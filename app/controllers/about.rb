class AboutController < ApplicationController
    skip_filter :require_login
    def help
    end
end
