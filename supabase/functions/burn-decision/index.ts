// Deploy:  supabase functions deploy burn-decision
// Secrets: supabase secrets set JEV_AI_API_URL=... JEV_AI_API_KEY=...

// Bring in Supabase Edge Runtime globals (Deno, Request, Response, fetch, etc.)

declare const Deno: {
  env: { get(key: string): string | undefined };
  serve(handler: (req: Request) => Promise<Response> | Response): void;
};

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Same task definition as test_with_jev.py (kept server-side so the app can't change it).
const QUESTIONS = {
  final_burn_classification: {
    type: "choice",
    instructions:
      "Combină distribuția de probabilități din vision_output cu răspunsurile " +
      "pacientului din chestionar pentru a determina gradul final al arsurii.",
    criteria: {
      "Grad I": "Eritem superficial, fără vezicule, durere ușoară.",
      "Grad II":
        "Afectare parțială a dermului, prezența veziculelor (bășici), durere moderată/intensă.",
      "Grad III":
        "Afectare totală a dermului, aspect alb/waxy/charred, posibil fără durere din cauza distrugerii nervilor.",
    },
  },
};

const json = (body: unknown, status = 200): Response =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

interface VisionOutput {
  status: string;
  probabilities: {
    degree_1: number;
    degree_2: number;
    degree_3: number;
  };
  image_brightness: number;
}

interface ChestionarItem {
  intrebare: string;
  raspuns: string;
}

interface RequestBody {
  vision_output: VisionOutput;
  chestionar: ChestionarItem[];
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const body = await req.json() as Partial<RequestBody>;
    const { vision_output, chestionar } = body;

    if (
      !vision_output?.probabilities ||
      typeof vision_output.image_brightness !== "number" ||
      !Array.isArray(chestionar) ||
      chestionar.length !== 5
    ) {
      return json({ error: "bad request: missing or invalid fields" }, 400);
    }

    const apiUrl = Deno.env.get("JEV_AI_API_URL");
    const apiKey = Deno.env.get("JEV_AI_API_KEY");

    if (!apiUrl || !apiKey) {
      return json({ error: "server misconfiguration: missing API secrets" }, 500);
    }

    const upstream = await fetch(apiUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ state: { vision_output, chestionar }, questions: QUESTIONS }),
      signal: AbortSignal.timeout(20_000),
    });

    const upstreamText = await upstream.text();

    if (!upstream.ok) {
      console.error(`Upstream error ${upstream.status}: ${upstreamText}`);
      return json(
        { error: `upstream returned ${upstream.status}`, detail: upstreamText },
        502,
      );
    }

    return new Response(upstreamText, {
      status: upstream.status,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("burn-decision error:", message);
    return json({ error: "upstream error", detail: message }, 502);
  }
});
