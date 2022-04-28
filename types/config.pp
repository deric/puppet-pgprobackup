# Backup schedule
type Pgprobackup::Config = Hash[String, Hash[
                                              Pgprobackup::Backup_type,Struct[{
                                                  Optional[hour]    => Cron::Hour,
                                                  Optional[minute]  => Cron::Minute,
                                                  Optional[month]   => Cron::Month,
                                                  Optional[weekday] => Cron::Weekday,
                                                  Optional[monthday] => Integer,
                                                }]
                                              ]
                                            ]