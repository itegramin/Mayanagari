export type RegeneratingStat = {
  value: number;
  capacity: number;
  updatedAt: number;
  secondsPerPoint: number;
};

export type RegeneratedStat = RegeneratingStat & {
  elapsedSeconds: number;
};

export function regenerateStat(
  stat: RegeneratingStat,
  now: number,
): RegeneratedStat {
  if (
    !Number.isInteger(stat.value) ||
    !Number.isInteger(stat.capacity) ||
    stat.capacity < 0 ||
    stat.value < 0 ||
    stat.value > stat.capacity ||
    !Number.isFinite(stat.updatedAt) ||
    !Number.isFinite(now) ||
    !Number.isInteger(stat.secondsPerPoint) ||
    stat.secondsPerPoint <= 0
  ) {
    throw new RangeError("Invalid regenerating stat");
  }

  const effectiveNow = Math.max(now, stat.updatedAt);
  const elapsedSeconds = Math.floor((effectiveNow - stat.updatedAt) / 1000);
  const pointsGained = Math.floor(elapsedSeconds / stat.secondsPerPoint);
  const value = Math.min(stat.capacity, stat.value + pointsGained);
  const secondsConsumed = pointsGained * stat.secondsPerPoint;
  const updatedAt =
    value === stat.capacity
      ? effectiveNow
      : stat.updatedAt + secondsConsumed * 1000;

  return {
    ...stat,
    value,
    updatedAt,
    elapsedSeconds,
  };
}
