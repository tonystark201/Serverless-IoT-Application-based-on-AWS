import logging
import logging.config


class LoggerHelper:

    @classmethod
    def configs(cls):
        return {
            'version': 1,
            'disable_existing_loggers': True,
            'formatters': {
                'verbose': {
                    'format': '%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s'
                },
                'simple': {
                    'format': '%(levelname)s %(message)s'
                },
            },
            'handlers': {
                'console': {
                    'level': 'DEBUG',
                    'class': 'logging.StreamHandler',
                    'formatter': 'verbose'
                }
            },
            'loggers': {
                'root': {
                    'handlers': ['console'],
                    'level': 'INFO',
                }
            }
        }

    @classmethod
    def create_logger(cls):
        logging.config.dictConfig(cls.configs())
        logger = logging.getLogger('root')
        logger.setLevel(logging.DEBUG)
        return logger

logger = LoggerHelper.create_logger()

