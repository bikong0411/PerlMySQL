#!/usr/bin/perl -w
#a lib for mysqlClient
#神经经病人思维广，二逼青年欢乐多
package SKY::MySQL;
use strict;
use DBI;
use DBD::mysql;
#
#@params string $host:$port
#@params string $user
#@params string $password
#@mysqldb  string $db
#@return objectref
#
sub new {
   my $class = shift;
   my($host,$user,$pwd,$db) = @_;
   $host .= ":3306" if not $host =~ /[^:]*:\d/;
   $db ||= "mysql";
   my $self = {};
   $self->{DB} = $db;
   my $dsn="DBI:mysql:$db;host=$host";
   $self->{DBH} = DBI->connect($dsn,$user,$pwd,{ RaiseError=>1 }) or die "Can't Connect MySQL:$!" if not exists $self->{DBH};
   bless $self,$class;
}
#
#fetch a row
#@params arrayref $cols eg. ['id','etc.']/['*']
#@params hashref eg. {'and' => {'id = ?' => 2},'or' => {'id <?' => 3' }/undef
#@params string $table
#@return hashref 
#
sub fetchRow {
    my $self = shift;
    my ($cols,$where,$table)=@_;
    my $contion = defined $where ? $self->_formatWhere($where) : "";
    my $sql = "select ";
    $sql .= join ",",@$cols;
    $sql .= " from $table ";
    $sql .= "where $contion" if defined $where;
    my $sth = $self->{DBH}->prepare($sql);
    $sth->execute();
    my $result = $sth->fetchrow_hashref();
    $result;
}
#
#fetch rows 
#@params arrayref $cols eg.['*']/['id','etc']
#@params hashref $where eg.{'and' => {'id =?' => 1},'or' => {'id<' => 2}}
#@params string $table
#@params string $order eg. id desc/asc
#@params int $offset
#@params int $limit
#
sub fetchAll {
    my $self = shift;
    my ($cols,$where,$table,$order,$offset,$limit)=@_;
    my $contion = defined $where ? $self->_formatWhere($where) : "";
    my $sql = "select ";
    $sql .= join ",",@$cols;
    $sql .= " from $table ";
    $sql .= "where $contion" if defined $where;
    $sql .= "order by $order" if defined $order;
    $sql .= "limit $offset" if defined $offset;
    $sql .= ",$limit" if defined $limit;
    my $sth = $self->{DBH}->prepare($sql);
    $sth->execute();
    my $result = $sth->fetchall_arrayref;
    $result;
}
#
#insert item to the table
#@params hashref $res eg.{'id'=> 2,'etc'=>'sd'}
#@params string $table
#@retuen int
#
sub insert {
    my $self = shift;
    my ($res,$table) = @_;
    my $sql = "insert into $table(";
    $sql .= join ",",keys %$res;
    $sql .= ') values(';
    $sql .= join ",",map {"'$_'"} values %$res;
    $sql .= ")";
    my $sth = $self->{DBH}->do($sql);
    $sth;
}
#
#update items
#@params hashref $data eg.{'a'=>2}
#@params hashref $where eg. {'and' => {'id =?' => 1}}
#@params string $table
#@return int
#
sub update {
    my $self = shift;
    my ($data,$where,$table) = @_;
    die "data is absent" if not defined($data);
    my $sql = "update $table set ";
    while(my($k,$v)=each(%$data))
    {
        $sql .= "$k = '$v' ,";
    }
    $sql =~ s/,$//;
    $sql .= defined $where ? "where ".$self->_formatWhere($where) : "";
    my $sth = $self->{DBH}->do($sql);
    $sth;  
}
#
#delete items
#@params hashref $where eg. {'and' => {'id' => 1}}
#@params string $table
#@return table
#
sub delete {
    my $self = shift;
    my ($where,$table) = @_;
    my $sql = "delete from $table ";
    $sql .= defined $where ? "where ".$self->_formatWhere($where) : "";
    my $sth = $self->{DBH}->do($sql);
    $sth;  
}
#
#replace into table..
#@params hashref $res eg.{'id'=> 2,'etc'=>'sd'}
#@params string $table
#@retuen int
#
sub replace {
    my $self = shift;
    my ($res,$table) = @_;
    my $sql = "replace into $table(";
    $sql .= join ",",keys %$res;
    $sql .= ') values(';
    $sql .= join ",",map {"'$_'"} values %$res;
    $sql .= ")";
    my $sth = $self->{DBH}->do($sql);
    $sth;
}
#
#execute a sql statment
#@params string $sql
#@return hashref/int
#
sub execsql {
    my $self = shift;
    my $sql = shift;
    my $sth = $self->{DBH}->prepare($sql);
    $sth->execute() ||  $sth->fetchall_arrayref;
}
#
#lastInsertId
#@return int
#
sub lastInsertId {
    my $self = shift;
    $self->{DBH}->last_insert_id(undef,undef,undef,undef);
}
#
#format where contion
#@params hashref $where eg.{'and' => {'id =?' => 2},...}
#@params string 
#
sub _formatWhere{
    my $self = shift;
    my $where = shift;
    my ($endwhere,$andwhere,$orwhere);
    for (keys %$where)
    {
        if ($_ eq "and")
        {
           my $val = $where->{$_};
           while(my ($k,$v) = each(%$val))
           {
              $k =~ s/\?/$v/;
              $andwhere .= "and $k ";
           }
        }
        if ($_ eq "or")
        {
           my $val = $where->{$_};
           while(my ($k,$v) = each(%$val))
           {
              $k =~ s/\?/$v/;
              $orwhere .= "or $k ";
           }
        }
    }
    $andwhere =~ s/^and// if defined $andwhere;
    if(defined($andwhere))
    {
       $orwhere = defined $orwhere ? $orwhere : "";
       $endwhere = "$andwhere $orwhere";
    }
    else
    {
       $endwhere = ($andwhere =~ s/^or//);
    }
    $endwhere;
}
1;
