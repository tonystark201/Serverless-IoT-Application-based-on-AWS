import psycopg2
from worker.commons import logger
from worker.commons.settings import configs


class PostgreHelper:

    def __init__(self):
        self.username = configs.dbsettings.User
        self.password = configs.dbsettings.Password
        self.dbname = configs.dbsettings.DbName
        self.table = configs.dbsettings.TableName
        self.host = configs.dbsettings.Host
        self.port = configs.dbsettings.Port
        self.logger = logger
        self._conn = None

    @property
    def conn(self):
        if not self._conn:
            try:
                self._conn = psycopg2.connect(
                    database=self.dbname,
                    user = self.username,
                    password = self.password,
                    host = self.host,
                    port = self.port
                )
            except Exception as e:
                self.logger.error('Error: Can`t connect postgres instance')
                self.logger.error(e)
                raise e
            self._conn.autocommit = True
        return self._conn

    def _exec(self,sql):
        try:
            with self.conn.cursor() as c:
                c.execute(sql)
        except psycopg2.DatabaseError as e:
            self.logger.error(e)

    def insert(self,kwargs: dict):
        assert isinstance(kwargs, dict), "kwargs must dict types"
        values = []
        values.append(f"to_timestamp({kwargs.get('ts')})")
        values.append(f"'{kwargs.get('dtype')}'")
        values.append(str(kwargs.get('counts')))
        values.append(f"'{kwargs.get('message')}'")
        values = ','.join(values)
        sql = "insert into {} values ({});".format(self.table,values)
        logger.info(f"SQL: {sql}")
        self._exec(sql)

    def retrieve_by_timestamp(self,kwargs):
        assert isinstance(kwargs, dict), "kwargs must dict types"
        ts = kwargs.pop('ts')
        sql = f"select * from {self.table} where ts = to_timestamp({ts});"
        self.logger.info(f'SQL: {sql}')
        return self._exec(sql)

    def update_by_timestamp(self,kwargs:dict):
        assert isinstance(kwargs, dict), "kwargs must dict types"
        ts = kwargs.pop('ts')
        values = []
        for k,v in kwargs.items():
            values.append(k)
            if k == "ts":
                values.append(f"to_timestamp({v})")
            if k == "dtype" or k == "message":
                values.append(f"'{v}'")
            if k == "counts":
                values.append(str(v))
        values = ('{}={},'*(len(kwargs)-1) + '{}={}').format(*values)
        sql = f'update {self.table} set {values} where ts = to_timestamp({ts});'
        self.logger.info(f"SQL: {sql}")
        self._exec(sql)
