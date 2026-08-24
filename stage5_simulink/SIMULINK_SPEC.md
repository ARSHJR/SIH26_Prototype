# Simulink Model Spec — Stage 5 (Telemedicine Screening Workflow)

Simulink models are graphical block diagrams, not text files — this is what to
actually build in the Simulink canvas. For a 12-hour demo, keep this simple;
the point is showing a working, parameter-adjustable throughput model, not a
fully realistic queueing simulation.

## Minimal viable block diagram

1. **Signal source block** representing patient arrivals — a `Pulse Generator`
   or `Random Number` block set to represent patients arriving at a configurable
   rate (patients/hour at a PHC).

2. **Delay/transport block** representing image transmission — a `Transport
   Delay` block with delay time driven by a `bandwidth` parameter you expose
   as a tunable variable (so you can show a judge "watch what happens if we
   reduce bandwidth").

3. **Queue block** — if SimEvents is available in your license, use a proper
   `Server`/`Queue` block pair representing the ophthalmologist review capacity
   (configurable service rate = reviews/hour per ophthalmologist × number of
   ophthalmologists). If SimEvents isn't available, approximate with a
   `Rate Limiter` + `Integrator` combination to show backlog accumulation over
   time — cruder, but still demonstrates the concept.

4. **Scope/output block** — plot backlog size over simulated time, so you can
   show live: "at current camera + reviewer capacity, backlog grows
   unboundedly — need N more reviewers to keep pace with 100,000 patients/year."

## Parameters to expose as adjustable (this is the actual demo moment)

- Number of PHC camera stations (affects arrival rate)
- Network bandwidth (affects transport delay)
- Number of reviewing ophthalmologists (affects service rate)

## What to show a judge live

Open the model, change "number of ophthalmologists" from e.g. 2 to 5, re-run
the simulation, and show the backlog curve flattening out. That's the whole
point of this stage — a live, interactive resource-allocation decision tool,
not just a static diagram.

## If genuinely short on time

A simplified version using just `Pulse Generator` → `Transport Delay` →
`Scope`, with the delay value manually tied to a `Slider Gain` block the
judge can drag live, still satisfies "model the pipeline and show resource
trade-offs" without needing SimEvents at all.
