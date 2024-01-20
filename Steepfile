# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature 'sig'

  check 'lib'

  # TODO: change to strict. cf. soutaro/steep/pull#964
  #   configure_code_diagnostics(D::Ruby.strict)
  configure_code_diagnostics(D::Ruby.lenient)
end
