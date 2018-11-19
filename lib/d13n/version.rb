module D13n
  module VERSION
    MAJOR     = 0
    MINOR     = 4
    TINY      = 5

    STRING = [MAJOR, MINOR, TINY].join('.')

    CODENAME = 'd13n'
  end

  NAME = 'd13n'.freeze
  RELEASE  = "#{NAME} #{VERSION::STRING} codename #{VERSION::CODENAME}".freeze
end
