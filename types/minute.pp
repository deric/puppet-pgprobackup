type Pgprobackup::Minute = Variant[
                          Integer[0,59],
                          String,
                          Tuple[Variant[String, Integer[0,59]], 1, default]
                        ]