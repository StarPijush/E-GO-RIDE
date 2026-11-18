import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { RideMap } from "@/components/map/ride-map";
import type { Place } from "@/lib/domain/types";

const placeA: Place = {
  id: "place-001",
  label: "Jhargram Railway Station",
  address: "Jhargram, West Bengal",
  kind: "poi",
  lat: 22.4529,
  lng: 86.9003,
};

const placeB: Place = {
  id: "place-006",
  label: "Jhargram College",
  address: "Jhargram, West Bengal",
  kind: "poi",
  lat: 22.461,
  lng: 86.912,
};

describe("ride map", () => {
  it("shows the fallback instead of Leaflet when the map is disabled", () => {
    render(<RideMap pickup={placeA} destination={placeB} />);

    expect(
      screen.getByRole("region", { name: "Map showing pickup and destination" }),
    ).toBeInTheDocument();
    expect(screen.getByText(/showing locations/)).toBeInTheDocument();
    expect(screen.getByText(/Jhargram Railway Station/)).toBeInTheDocument();
    expect(screen.getByText(/Jhargram College/)).toBeInTheDocument();
    expect(document.querySelector(".leaflet-container")).toBeNull();
  });

  it("explains that the map preview is disabled", () => {
    render(<RideMap pickup={placeA} destination={placeB} />);

    expect(screen.getByText("Map preview disabled - showing locations")).toBeInTheDocument();
  });

  it("names the route in the fallback", () => {
    render(<RideMap pickup={placeA} destination={placeB} />);

    expect(
      screen.getByRole("img", {
        name: "Map preview from Jhargram Railway Station to Jhargram College",
      }),
    ).toBeInTheDocument();
  });
});
