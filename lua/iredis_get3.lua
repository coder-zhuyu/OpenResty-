local redis = require "resty.iredis"

local function get_from_redis(key)
    local red = redis:new({["ip"]="127.0.0.1", ["port"]=6379})
    local res, err = red:get(key)
    return res
end

local function set_to_cache(key, value, exptime)
    if not exptime then
        exptime = 0
    end
    local cache_ngx = ngx.shared.cache_ngx
    local succ, err, farcible = cache_ngx:set(key, value, exptime)
    return succ
end

local function get_from_cache(key)
    local cache_ngx = ngx.shared.cache_ngx
    local value = cache_ngx:get(key)
    if not value then
        local lock = require "resty.lock"
        local lock = lock:new("my_locks")
        lock:lock("my_key")
        value = get_from_redis(key)
        lock:unlock()

        set_to_cache(key, value, 100)
    end
    return value
end

local res = get_from_cache('ad0001')
ngx.say(res)

