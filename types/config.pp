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
                                                  Optional[log_dir] => Stdlib::AbsolutePath,
                                                  Optional[log_file] => String,
                                                  Optional[log_console] => String,
                                                  Optional[log_rotation_size] => String,
                                                  Optional[log_rotation_age] => String,
                                                  Optional[redirect_console] => Boolean,
                                                  Optional[log_level_file] => Pgprobackup::LogLevel,
                                                  Optional[log_level_console] => Pgprobackup::LogLevel,
                                                }]
                                              ]
                                            ]