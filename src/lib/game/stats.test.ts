import { describe, expect, it } from "vitest";
import { regenerateStat } from "./stats";

describe("regenerateStat", () => {
  const minute = 60_000;

  it("adds only complete intervals and carries the partial interval forward", () => {
    const result = regenerateStat(
      { value: 4, capacity: 10, updatedAt: 0, secondsPerPoint: 60 },
      149_000,
    );

    expect(result.value).toBe(6);
    expect(result.updatedAt).toBe(120_000);
  });

  it("does not bank time while capped", () => {
    const result = regenerateStat(
      { value: 9, capacity: 10, updatedAt: 0, secondsPerPoint: 60 },
      10 * minute,
    );

    expect(result.value).toBe(10);
    expect(result.updatedAt).toBe(10 * minute);
  });

  it("does not move the checkpoint backwards when the clock is earlier", () => {
    const result = regenerateStat(
      { value: 2, capacity: 10, updatedAt: 120_000, secondsPerPoint: 60 },
      0,
    );

    expect(result.value).toBe(2);
    expect(result.updatedAt).toBe(120_000);
  });

  it("rejects invalid stat state", () => {
    expect(() =>
      regenerateStat(
        { value: 11, capacity: 10, updatedAt: 0, secondsPerPoint: 60 },
        60_000,
      ),
    ).toThrow(RangeError);
  });
});
