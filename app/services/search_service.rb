class SearchService
  attr_reader :queries, :filters
  attr_reader :_includes, :_orders

  def initialize(queries, filters)
    @queries = queries
    @filters = filters
  end

  def includes(includes)
    @_includes ||= []
    @_includes << includes
  end

  def order(order)
    @_orders ||= []
    @_orders << order
  end

  def query
    raise NotImplementedError
  end

  def total_count
    query.total_count
  end

  def to_a
    query.to_a
  end

  def offset(offset)
    @_offset = offset
  end

  def limit(limit)
    @_limit = limit
  end

  private

  def auto_query_for(field, value)
    case value
    when String, Numeric, Date
      { match: { field => value } }
    when Range
      { range: { field => { gte: value.min, lte: value.max } } }
    when Array
      # Array<String|Fixnum|Float> get shorthanded to a single match query
      if value.all? { |v| v.is_a?(String) || v.is_a?(Numeric) }
        auto_query_for(field, value.join(' '))
      else
        matchers = value.map { |v| auto_query_for(field, v) }
        { bool: { should: matchers } }
      end
    when Hash
      value.deep_transform_keys { |key| key.to_s == '$field' ? field : key }
    else
      value
    end
  end
end
