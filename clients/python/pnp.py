import json
import requests

class Client:

  def __init__(self, uri, user, password):
    self.uri = uri
    self.user = user
    self.password = password

  def trigger(self, event, data):
    return self.__post("/api/1/event/trigger", event, data)

  def read(self, event, data):
    return self.__post("/api/1/event/read", event, data)

  def __post(self, endpoint, event, data):
    url = self.uri + endpoint
    headers = {"content-type": "application/json"}
    payload = {
      "name": event,
      "data": data
    }

    r = requests.post(
      url,
      auth=(self.user, self.password),
      headers=headers,
      data=json.dumps(payload)
    )

    return r.text

  def __getattr__(self, name):
    def _missing(*args, **kwargs):
      if name.startswith("payout_"):
          kwargs["account_role"] = name[7:]
          return self.trigger("payout", kwargs)

      else:
        if name.startswith("get_"):
          return self.read(name[4:], kwargs)
        else:
          return self.trigger(name, kwargs)

    return _missing
