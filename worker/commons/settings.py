import dataclasses


@dataclasses.dataclass(
    init=True,
    repr=True,
    unsafe_hash=True,
    frozen=True
)
class DBSettings:
    User = "station"
    Password = "station123456"
    DbName = "stationdb"
    TableName = "stations"
    Host = "xxxxxx"
    Port = 5432


@dataclasses.dataclass(
    init=True,
    repr=True,
    unsafe_hash=True,
    frozen=True
)
class StationSettings:
    PolicyName = "station_policy"
    PolicyDoc = {
        "Version": "2012-10-17",
        "Statement": [{"Effect": "Allow", "Action": "iot:*", "Resource": "*"}],
    }


@dataclasses.dataclass(
    init=True,
    repr=True,
    unsafe_hash=True,
    frozen=True
)
class CertiSetting:
    '''
    RSA:
     https://www.amazontrust.com/repository/AmazonRootCA2.pem
     https://www.amazontrust.com/repository/AmazonRootCA1.pem
    '''
    Cert = "certificatePem"
    PubKey = "public-key"
    PriKey = "private-key"
    CA = "root-ca"
    CaUrl = "https://www.amazontrust.com/repository/AmazonRootCA1.pem"


@dataclasses.dataclass(
    init=True,
    repr=True,
    unsafe_hash=True,
    frozen=True
)
class Configs:
    certification = CertiSetting()
    station_settings = StationSettings()
    dbsettings = DBSettings()


configs = Configs()
