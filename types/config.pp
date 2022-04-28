# Backup schedule
type Pgprobackup::Config = Hash[String, Hash[
                                              Pgprobackup::Backup_type,Struct[{
                                                  Optional[hour]   => Pgprobackup::Hour,
                                                  Optional[minute] => Pgprobackup::Minute,
                                                  Optional[month]  => Pgprobackup::Month,
                                                  Optional[weekday] => Pgprobackup::Weekday,
                                                  Optional[monthday] => Pgprobackup::Monthday,
                                                  Optional[threads] => Integer,
                                                  Optional[retention_redundancy] => Integer,
                                                  Optional[retention_window] => Integer,
                                                  Optional[delete_expired] => Boolean,
                                                  Optional[merge_expired] => Boolean,
                                                  Optional[temp_slot] => Boolean,
                                                  Optional[slot] => String,
                                                  Optional[validate] => Boolean,
                                                  Optional[compress_algorithm] => String,
                                                  Optional[compress_level] => Integer,
                                                  Optional[archive_wal] => Boolean,
                                                }]
                                              ]
                                            ]