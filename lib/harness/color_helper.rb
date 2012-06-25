# Displaying text in color
module BVT::Harness
  module ColorHelpers

    def red(text)
      "\e[31m#{text}\e[0m"
    end

    def green(text)
      "\e[32m#{text}\e[0m"
    end

    def yellow(text)
      "\e[33m#{text}\e[0m"
    end

    def cyan(text)
      "\e[36m#{text}\e[0m"
    end

  end
end
