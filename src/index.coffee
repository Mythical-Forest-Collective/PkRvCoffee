() ->
  PK_TOKEN = "Token goes here"

  # Load the `axios` module
  script = document.createElement('script')
  script.src = "https://cdn.jsdelivr.net/npm/axios@1.1.2/dist/axios.min.js"
  document.body.appendChild(script)

  # PKLib implementation begin
  # Constants for `pklib` (ported from TS to Coffee)
  PK_BASE_URL = "https://api.pluralkit.me/v2"
  METHODS = ['get', 'post', 'delete', 'patch', 'put']
  NOOP = () -> {}

  # Scheduled API calls
  scheduled = []

  # Parse PK API data
  parseData = (code, data) ->
    if (code == 200)
      return data
    else if (code == 204)
      return

    throw data;

  runAPI = () ->
    if scheduled.length == 0
      return

    _a = scheduled.shift()
    axiosData = _a.axiosData
    res = _a.res
    rej = _a.rej

    axios(axiosData)
      .then((resp) -> res(parseData(resp.status, resp.data)))
      .catch((err) -> rej(err))

  setInterval(runAPI, 500)

  # Note that this method is literally just translated from
  # TS to JS to Coffee, so it's incredibly messy
  pk = () ->
    route = []
    handler =
      get: (_, name) ->
        if methods.includes(name)
          return (_a) ->
            _b = if _a == undefined then {} else _a
            _c = _b.data
            data = if _c == undefined then undefined else _c
            _d = _b.query
            query = if _d == undefined then null else _d
            new Promise((res, rej) ->
              scheduled.push
                res: res
                rej: rej
                axiosData:
                  url: baseURL + '/' + route.join('/') + (if query then '?' + Object.keys(query).map(((x) ->
                    x + '=' + query[x]
                  )).join('&') else '')
                  method: name
                  headers:
                    authorization: PK_TOKEN
                    'content-type': if name == 'get' then undefined else 'application/json'
                  data: if ! !data then JSON.stringify(data) else undefined
                  validateStatus: ->
                    true
  )

        route.push name
        new Proxy(noop, handler)
      apply: (target, _, args) ->
        route.push.apply route, args.filter((x) ->
          x != null
        )
        new Proxy(noop, handler)
    new Proxy(noop, handler)    
  globalThis.pk = pk
  # PKLib implementation end

  latch_mode = false
  last_proxied_member = null


  SYSTEM_TAG = ""
  pk().systems('@me').get().then(sys -> SYSTEM_TAG = sys.tag)

  monkeypatchChannelSend = (channel) ->
    channel['origSend'] = channel.sendMessage
    channel.sendMessage = (data) ->
      msgData = {}
      if data['content']
        msgData = data
      else
        msgData.content = data

      if msgData.content.toLowerCase() == "pk;ap latch"
        latch_mode = !latch_mode
        if !latch_mode
          last_proxied_member = null
        msgData.content = "Latch set to "+latch_mode
        return await channel.sendMessage(msgData)

      m = last_proxied_member
      proxy_tag = null

      for member in members
        for proxy in member.proxy_tags
          if msgData.content.startsWith(proxy.prefix || "") and msgData.content.endsWith(proxy.suffix || "")
            m = member
            proxy_tag = proxy
            if latch_mode
              last_proxied_member = m
            break
        if proxy_tag
          break

      if m and channel.havePermission("Masquerade")
        msgData.masquerade = {}

        start = (proxy_tag.prefix || "").length
        end = msgData.content.length - (proxy_tag.suffix || "").length

        msgData.content = msgData.content.slice(start, end)

        msgData.masquerade.name = "#{(m.display_name || m.name)} #{SYSTEM_TAG}"
        if msgData.masquerade.name.length > 32
          msgData.masquerade.name = m.display_name || m.name
        if msgData.masquerade.name.length > 32
          msgData.masquerade.name = "#{m.name} #{SYSTEM_TAG}"
        if msgData.masquerade.name.length > 32
          msgData.masquerade.name = m.display_name || m.name
        if msgData.masquerade.name.length > 32
          msgData.masquerade.name = m.name
        if msgData.masquerade.name.length > 32
          msgData.masquerade.name = "NAME TOO BIG"

        msgData.masquerade.avatar = m.avatar_url

    return await this.origSend(msgData)

  setup = () ->
    client = window.controllers.client.getReadyClient()
    client.on "message", (message) ->
      if message.author == client.user and !message.channel.origSend
        monkeypatchChannelSend(message.channel)
        await message.channel.sendMessage(message.content)
        await message.delete()

  setTineout(setup, 3e3)

  return unload: () ->
    script.remove()
    console.log('[PkRvCoffee] Plugin unloaded!');
