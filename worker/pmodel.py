import json
import uuid

from pydantic import BaseModel, validator
from datetime import datetime


class MessageModel(BaseModel):
    message: str

class MetaModel(BaseModel):
    topic: str
    timestamp: datetime

    class Config:
        json_encoders = {
            datetime: lambda v: v.timestamp(),
        }


class PayloadModel(BaseModel):
    id: str
    method: str
    params: MessageModel

    @validator("id")
    def id_must_uuid(cls, v):
        try:
            uuid.UUID(v)
        except Exception:
            raise ValueError("uuid must UUID type")


class StationModel(BaseModel):
    meta: MetaModel
    payload: PayloadModel

    class Config:
        json_encoders = {
            datetime: lambda v: v.timestamp(),
        }


if __name__ == '__main__':
    temp = {
        "meta": {
            'topic': "iot/station/123123",
            'timestamp': datetime.now().timestamp()
        },
        'payload': {
            'id': uuid.uuid1().hex,
            'method': 'Station Report',
            'params': {
                'message': json.dumps(
                    {
                        "type": "abc",
                        "counts": 10,
                        "message": "hello,world"
                    }
                )
            }
        }
    }

    try:
        temp = StationModel.parse_obj(temp)
    except Exception as e:
        print(e)
        raise e

