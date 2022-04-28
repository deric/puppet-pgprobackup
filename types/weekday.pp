type Pgprobackup::Weekday = Variant[
                          Integer[1,7],
                          String,
                          Tuple[Variant[String, Integer[1,7]], 1, default]
                        ]