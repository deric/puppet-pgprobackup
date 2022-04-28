# Backup schedule
type Pgprobackup::Config = Hash[String, Hash[
                                              Pgprobackup::Backup_type,Struct[{
                                                  Optional[hour]   => Pgprobackup::Hour,
                                                  Optional[minute] => Pgprobackup::Minute,
                                                  Optional[month]  => Pgprobackup::Month,
                                                  Optional[weekday] => Pgprobackup::Weekday,
                                                  Optional[monthday] => Pgprobackup::Monthday
                                                }]
                                              ]
                                            ]