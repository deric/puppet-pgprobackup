type Pgprobackup::Monthday = Variant[
                          Integer[1,31],
                          String,
                          Tuple[Variant[String, Integer[1,31]], 1, default]
                        ]