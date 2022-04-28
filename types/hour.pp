type Pgprobackup::Hour = Variant[
                          Integer[0,23],
                          String,
                          Tuple[Variant[String, Integer[0,23]], 1, default]
                        ]