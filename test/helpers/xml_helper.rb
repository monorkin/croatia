# frozen_string_literal: true

module XMLHelper
  def self.canonicalize(doc)
    output = StringIO.new
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    formatter.write(doc.root, output)
    output.string
  end

  def assert_xml_equal(expected, actual)
    expected_doc = expected.is_a?(REXML::Document) ? expected : REXML::Document.new(expected)
    actual_doc = actual.is_a?(REXML::Document) ? actual : REXML::Document.new(actual)

    assert_equal(
      XMLHelper.canonicalize(expected_doc),
      XMLHelper.canonicalize(actual_doc),
      "XML documents are not equal"
    )
  end
end
