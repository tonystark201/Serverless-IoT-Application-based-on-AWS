import json
from pydantic import ValidationError
from commons.logger import logger
from storage import PostgreHelper
from pmodel import StationModel
from worker.commons.utils import Singleton


class Station(metaclass=Singleton):

    def __init__(self):
        self.helper = PostgreHelper()
        self.logger = logger

    def _parse(self, body):
        self.logger.info("Parse event")
        try:
            body = json.loads(body)
        except json.JSONDecodeError as e:
            raise e
        return body

    def _validate(self,body):
        self.logger.info(f"Validate body: {body}")
        try:
            station = StationModel.parse_obj(body)
        except ValidationError as e:
            raise e
        return  station

    def _store(self,kwargs:dict):
        self.logger.info("Store message")
        result = self.helper.retrieve_by_timestamp({'ts':kwargs['ts']})
        if result:
            self.helper.update_by_timestamp(kwargs = kwargs)
        else:
            self.helper.insert(kwargs)

    def exec(self,body):
        body = self._parse(body)
        station = self._validate(body)
        ts = station.meta.timestamp.timestamp()
        msg:dict = json.loads(station.payload.params.message)
        msg.update({'ts':ts})
        self.logger.info(f'Message: {msg}')
        self._store(kwargs=msg)

def lambda_handler(event, context):
    """
    lambda handler
    """
    records = event.get('Records')
    body = records[0].get('body')
    Station().exec(body)
    return {
        'event': event
    }
