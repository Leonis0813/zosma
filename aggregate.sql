INSERT IGNORE INTO
  candle_sticks
(
  SELECT
    NULL,
    axis.from,
    axis.to,
    axis.pair,
    axis.interval,
    open.rate AS open,
    close.rate AS close,
    high_low.high AS high,
    high_low.low AS low
  FROM (
    SELECT
      '$BEGIN' AS 'from',
      '$END' AS 'to',
      '$PAIR' AS pair,
      '$INTERVAL' AS 'interval'
  ) AS axis
  LEFT JOIN (
    SELECT
      pair,
      bid AS rate
    FROM
      rates
    WHERE
      time BETWEEN '$BEGIN' AND '$END'
      AND pair = '$PAIR'
    ORDER BY
      time
    LIMIT
      1
  ) AS open
  ON
    axis.pair = open.pair
  LEFT JOIN (
    SELECT
      pair,
      bid AS rate
    FROM
      rates
    WHERE
      time BETWEEN '$BEGIN' AND '$END'
      AND pair = '$PAIR'
    ORDER BY
      time DESC
    LIMIT
      1
  ) AS close
  ON
    axis.pair = close.pair
  LEFT JOIN (
    SELECT
      pair,
      MAX(bid) AS high,
      MIN(bid) AS low
    FROM
      rates
    WHERE
      time BETWEEN '$BEGIN' AND '$END'
      AND pair = '$PAIR'
  ) AS high_low
  ON
    axis.pair = high_low.pair
)
