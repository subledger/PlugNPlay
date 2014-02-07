import json
import requests

class Client:

  def __init__(self, uri, user, password):
    self.uri = uri
    self.user = user
    self.password = password

  def trigger(self, event, data):
    url = self.uri + "/api/1/event/trigger"
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
        return self.trigger(name, kwargs)

    return _missing
