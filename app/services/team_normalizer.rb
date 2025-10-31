# TeamNormalizer - Utility for normalizing team names across APIs
#
# Prepares for future multi-API support by standardizing team names
# into a consistent format that can be matched across different data sources

class TeamNormalizer
  # Normalize a team name into a standardized format
  # Examples:
  #   "Los Angeles Lakers" -> "los_angeles_lakers"
  #   "The Dallas Cowboys" -> "dallas_cowboys"
  #   "FC Barcelona" -> "fc_barcelona"
  def self.normalize(team_name)
    return nil if team_name.blank?

    team_name
      .downcase                           # Convert to lowercase
      .gsub(/^the\s+/i, '')              # Remove leading "The"
      .gsub(/[^a-z0-9\s]/, '')           # Remove special characters
      .strip                              # Remove leading/trailing spaces
      .gsub(/\s+/, '_')                  # Replace spaces with underscores
      .gsub(/_+/, '_')                   # Collapse multiple underscores
      .gsub(/^_|_$/, '')                 # Remove leading/trailing underscores
  end

  # Find or create a team by normalized name
  # This ensures we don't create duplicate teams when the same team
  # appears with slight name variations
  def self.find_or_create_team(league:, name:, **attributes)
    normalized = normalize(name)

    team = Team.find_or_initialize_by(
      league: league,
      normalized_name: normalized
    )

    # Set attributes if it's a new record or updating is allowed
    if team.new_record?
      team.name = name
      team.active = true
      team.assign_attributes(attributes)
    end

    team.save! if team.changed?
    team
  end

  # Match a team name to an existing team in the database
  # Useful for future multi-API support where different APIs
  # might use slightly different team names
  def self.find_by_name(league:, name:)
    normalized = normalize(name)
    Team.find_by(league: league, normalized_name: normalized)
  end

  # Future: Map team names across different APIs
  # This will be useful when we add additional data sources
  #
  # Example:
  #   normalize_across_apis("LA Lakers", "Los Angeles Lakers")
  #   # => Both map to "los_angeles_lakers"
  def self.normalize_across_apis(*names)
    names.map { |name| normalize(name) }.uniq.first
  end
end

