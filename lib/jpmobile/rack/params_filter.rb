# リクエストパラメータの変換
module Jpmobile
  class ParamsFilter
    def initialize(app)
      @app = app
    end

    def call(env)
      # 入力
      if (mobile = env['rack.jpmobile']) && mobile.apply_params_filter?
        # パラメータをkey, valueに分解
        # form_params
        if env['REQUEST_METHOD'] != 'GET' &&
           env['REQUEST_METHOD'] != 'HEAD' &&
           !env['CONTENT_TYPE'].match?(%r{application/json|application/xml})

          env['rack.input'] = StringIO.new(parse_query(env['rack.input'].read, mobile))
        end

        # query_params
        env['QUERY_STRING'] = parse_query(env['QUERY_STRING'], mobile)
      end

      status, env, body = @app.call(env)

      [status, env, body]
    end

    private

    def to_internal(str, mobile)
      ::Rack::Utils.escape(mobile.to_internal(::Rack::Utils.unescape(str)))
    end

    def parse_query(str, mobile)
      return nil unless str

      new_array = []
      str.split('&').each do |param_pair|
        k, v = param_pair.split('=')
        k = to_internal(k, mobile) if k
        v = to_internal(v, mobile) if v
        new_array << "#{k}=#{v}" if k
      end

      new_array.join('&')
    end
  end
end
