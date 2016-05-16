--This is what's produced by a single-term query

SELECT
  participants.*,
  COUNT(efforts.id)       AS effort_count,
  ROUND(AVG((extract(EPOCH FROM (current_date - events.first_start_time)) / 60 / 60 / 24 / 365.25) +
            efforts.age)) AS participant_age
FROM "participants"
  LEFT OUTER JOIN efforts ON (efforts.participant_id = participants.id)
  INNER JOIN events ON (events.id = efforts.event_id)
WHERE (participants.id IN (
  SELECT participants.id
  FROM "participants"
  WHERE ("participants"."country_code" ILIKE '')
  UNION SELECT participants.id
        FROM "participants"
        WHERE ("participants"."state_code" ILIKE '')
  UNION SELECT participants.id
        FROM "participants"
        WHERE ("participants"."first_name" ILIKE '%oveson%')
  UNION SELECT participants.id
        FROM "participants"
        WHERE ("participants"."last_name" ILIKE 'oveson%')))
GROUP BY participants.id
ORDER BY "participants"."last_name" ASC, "participants"."first_name" ASC
LIMIT 25
OFFSET 0;

--And this is a two-term query using standard dot-chaining

SELECT
  participants.*,
  COUNT(efforts.id)       AS effort_count,
  ROUND(AVG((extract(EPOCH FROM (current_date - events.first_start_time)) / 60 / 60 / 24 / 365.25) +
            efforts.age)) AS participant_age
FROM "participants"
  LEFT OUTER JOIN efforts ON (efforts.participant_id = participants.id)
  INNER JOIN events ON (events.id = efforts.event_id)
WHERE (participants.id IN (SELECT participants.id
                           FROM "participants"
                           WHERE ("participants"."country_code" ILIKE '')
                           UNION SELECT participants.id
                                 FROM "participants"
                                 WHERE ("participants"."state_code" ILIKE '')
                           UNION SELECT participants.id
                                 FROM "participants"
                                 WHERE ("participants"."first_name" ILIKE '%mark%')
                           UNION SELECT participants.id
                                 FROM "participants"
                                 WHERE ("participants"."last_name" ILIKE 'mark%'))) AND
      (participants.id IN (SELECT participants.id
                           FROM "participants"
                           WHERE (participants.id IN (SELECT participants.id
                                                      FROM "participants"
                                                      WHERE ("participants"."country_code" ILIKE '')
                                                      UNION SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."state_code" ILIKE '')
                                                      UNION SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."first_name" ILIKE '%mark%')
                                                      UNION SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."last_name" ILIKE 'mark%'))) AND
                                 ("participants"."country_code" ILIKE '')
                           UNION SELECT participants.id
                                 FROM "participants"
                                 WHERE (participants.id IN (SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."country_code" ILIKE '')
                                                            UNION SELECT participants.id
                                                                  FROM "participants"
                                                                  WHERE ("participants"."state_code" ILIKE '')
                                                            UNION SELECT participants.id
                                                                  FROM "participants"
                                                                  WHERE ("participants"."first_name" ILIKE '%mark%')
                                                            UNION SELECT participants.id
                                                                  FROM "participants"
                                                                  WHERE ("participants"."last_name" ILIKE 'mark%'))) AND
                                       ("participants"."state_code" ILIKE 'CO')
                           UNION SELECT participants.id
                                 FROM "participants"
                                 WHERE (participants.id IN (SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."country_code" ILIKE '')
                                                            UNION SELECT participants.id
                                                                  FROM "participants"
                                                                  WHERE ("participants"."state_code" ILIKE '')
                                                            UNION SELECT participants.id
                                                                  FROM "participants"
                                                                  WHERE ("participants"."first_name" ILIKE '%mark%')
                                                            UNION SELECT participants.id
                                                                  FROM "participants"
                                                                  WHERE ("participants"."last_name" ILIKE 'mark%'))) AND
                                       ("participants"."first_name" ILIKE '%colorado%')
                           UNION SELECT participants.id
                                 FROM "participants"
                                 WHERE (participants.id IN (SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."country_code" ILIKE '')
                                                            UNION SELECT participants.id
                                                                  FROM "participants"
                                                                  WHERE ("participants"."state_code" ILIKE '')
                                                            UNION SELECT participants.id
                                                                  FROM "participants"
                                                                  WHERE ("participants"."first_name" ILIKE '%mark%')
                                                            UNION SELECT participants.id
                                                                  FROM "participants"
                                                                  WHERE ("participants"."last_name" ILIKE 'mark%'))) AND
                                       ("participants"."last_name" ILIKE 'colorado%')))
GROUP BY participants.id
ORDER BY "participants"."last_name" ASC, "participants"."first_name" ASC
LIMIT 25
OFFSET 0;

--Whereas this is produced using a combination of union_scope and intersect_scope:

SELECT
  participants.*,
  COUNT(efforts.id)       AS effort_count,
  ROUND(AVG((extract(EPOCH FROM (current_date - events.first_start_time)) / 60 / 60 / 24 / 365.25) +
            efforts.age)) AS participant_age
FROM "participants"
  LEFT OUTER JOIN efforts ON (efforts.participant_id = participants.id)
  INNER JOIN events ON (events.id = efforts.event_id)
WHERE (participants.id IN (SELECT participants.id
                           FROM "participants"
                           WHERE (participants.id IN (SELECT participants.id
                                                      FROM "participants"
                                                      WHERE ("participants"."country_code" ILIKE '')
                                                      UNION SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."state_code" ILIKE '')
                                                      UNION SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."first_name" ILIKE '%mark%')
                                                      UNION SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."last_name" ILIKE
                                                                   'mark%'))) INTERSECT SELECT participants.id
                                                                                        FROM "participants"
                                                                                        WHERE (participants.id IN
                                                                                               (SELECT participants.id
                                                                                                FROM "participants"
                                                                                                WHERE (
                                                                                                  "participants"."country_code"
                                                                                                  ILIKE '')
                                                                                                UNION SELECT
                                                                                                        participants.id
                                                                                                      FROM
                                                                                                        "participants"
                                                                                                      WHERE (
                                                                                                        "participants"."state_code"
                                                                                                        ILIKE '')
                                                                                                UNION SELECT
                                                                                                        participants.id
                                                                                                      FROM
                                                                                                        "participants"
                                                                                                      WHERE (
                                                                                                        "participants"."first_name"
                                                                                                        ILIKE
                                                                                                        '%oveson%')
                                                                                                UNION SELECT
                                                                                                        participants.id
                                                                                                      FROM
                                                                                                        "participants"
                                                                                                      WHERE (
                                                                                                        "participants"."last_name"
                                                                                                        ILIKE
                                                                                                        'oveson%')))))
GROUP BY participants.id
ORDER BY "participants"."last_name" ASC, "participants"."first_name" ASC
LIMIT 25
OFFSET 0;

--And here's a three-term query using union_scope and intersect_scope:

SELECT
  participants.*,
  COUNT(efforts.id)       AS effort_count,
  ROUND(AVG((extract(EPOCH FROM (current_date - events.first_start_time)) / 60 / 60 / 24 / 365.25) +
            efforts.age)) AS participant_age
FROM "participants"
  LEFT OUTER JOIN efforts ON (efforts.participant_id = participants.id)
  INNER JOIN events ON (events.id = efforts.event_id)
WHERE (participants.id IN (SELECT participants.id
                           FROM "participants"
                           WHERE (participants.id IN (SELECT participants.id
                                                      FROM "participants"
                                                      WHERE ("participants"."country_code" ILIKE '')
                                                      UNION SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."state_code" ILIKE '')
                                                      UNION SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."first_name" ILIKE '%mark%')
                                                      UNION SELECT participants.id
                                                            FROM "participants"
                                                            WHERE ("participants"."last_name" ILIKE
                                                                   'mark%'))) INTERSECT SELECT participants.id
                                                                                        FROM "participants"
                                                                                        WHERE (participants.id IN
                                                                                               (SELECT participants.id
                                                                                                FROM "participants"
                                                                                                WHERE (
                                                                                                  "participants"."country_code"
                                                                                                  ILIKE '')
                                                                                                UNION SELECT
                                                                                                        participants.id
                                                                                                      FROM
                                                                                                        "participants"
                                                                                                      WHERE (
                                                                                                        "participants"."state_code"
                                                                                                        ILIKE '')
                                                                                                UNION SELECT
                                                                                                        participants.id
                                                                                                      FROM
                                                                                                        "participants"
                                                                                                      WHERE (
                                                                                                        "participants"."first_name"
                                                                                                        ILIKE
                                                                                                        '%oveson%')
                                                                                                UNION SELECT
                                                                                                        participants.id
                                                                                                      FROM
                                                                                                        "participants"
                                                                                                      WHERE (
                                                                                                        "participants"."last_name"
                                                                                                        ILIKE
                                                                                                        'oveson%'))) INTERSECT SELECT
                                                                                                                                 participants.id
                                                                                                                               FROM
                                                                                                                                 "participants"
                                                                                                                               WHERE
                                                                                                                                 (
                                                                                                                                   participants.id
                                                                                                                                   IN
                                                                                                                                   (SELECT
                                                                                                                                      participants.id
                                                                                                                                    FROM
                                                                                                                                      "participants"
                                                                                                                                    WHERE
                                                                                                                                      (
                                                                                                                                        "participants"."country_code"
                                                                                                                                        ILIKE
                                                                                                                                        '')
                                                                                                                                    UNION SELECT
                                                                                                                                            participants.id
                                                                                                                                          FROM
                                                                                                                                            "participants"
                                                                                                                                          WHERE
                                                                                                                                            (
                                                                                                                                              "participants"."state_code"
                                                                                                                                              ILIKE
                                                                                                                                              'CO')
                                                                                                                                    UNION SELECT
                                                                                                                                            participants.id
                                                                                                                                          FROM
                                                                                                                                            "participants"
                                                                                                                                          WHERE
                                                                                                                                            (
                                                                                                                                              "participants"."first_name"
                                                                                                                                              ILIKE
                                                                                                                                              '%colorado%')
                                                                                                                                    UNION SELECT
                                                                                                                                            participants.id
                                                                                                                                          FROM
                                                                                                                                            "participants"
                                                                                                                                          WHERE
                                                                                                                                            (
                                                                                                                                              "participants"."last_name"
                                                                                                                                              ILIKE
                                                                                                                                              'colorado%')))))
GROUP BY participants.id
ORDER BY "participants"."last_name" ASC, "participants"."first_name" ASC
LIMIT 25
OFFSET 0