type Pgprobackup::Month = Variant[
                          Integer[1,12],
                          String,
                          Tuple[Variant[String, Integer[1,12]], 1, default]
                        ]