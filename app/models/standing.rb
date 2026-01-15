class Standing < ApplicationRecord
  belongs_to :tournament
  belongs_to :tournaments_player

  after_commit :update_merged_standings, on: [:create, :update, :destroy]

  def merged_standings_config
    if tournaments_player and tournaments_player.group
      tournaments_player.group.merged_standings_config
    end
  end

  private
  def update_merged_standings
    config = self.merged_standings_config
    return unless config

    new_rec = {
      points: 0,
      median: 0,
      solkoff: 0,
      cumulative: 0,
      opposition_cumulative: 0,
      playing_black: 0,
      sb: 0,
      wins: 0,
      h2h_points: 0.0,
      h2h_cluster: 0,
      blacklisted: false
    }

    # for each group in separate tournaments
    config.groups.each do |grp|
      t_player = TournamentsPlayer.find_by(
        player: tournaments_player.player,
        group: grp)
      next unless t_player
      next if grp.completed_round == 0

      standing = Standing.find_by(tournaments_player: t_player, round: grp.completed_round)
      next unless standing
    
      new_rec.keys.each do |k|
        if k == :blacklisted
          new_rec[k] ||= standing.send(k)
        else
          new_rec[k] += standing.send(k) || 0
        end
      end
    end

    merged_standing = MergedStanding.find_or_create_by(
        merged_standings_config: config,
        player: tournaments_player.player,
        labels: tournaments_player.labels,
      )

    merged_standing.update!(new_rec)
  end
end
