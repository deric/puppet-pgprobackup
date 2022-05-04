type Pgprobackup::Weekday = Variant[
                          Integer[0,7],
                          String,
                          Tuple[Variant[String, Integer[0,7]], 1, default]
                        ]