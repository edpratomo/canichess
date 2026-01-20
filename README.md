[![Ruby on Rails CI](https://github.com/edpratomo/canichess/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/edpratomo/canichess/actions/workflows/rubyonrails.yml)
[![Docker Image CI](https://github.com/edpratomo/canichess/actions/workflows/docker-image.yml/badge.svg)](https://github.com/edpratomo/canichess/actions/workflows/docker-image.yml)

# Canichess CEO

**Chess Events Organizer** for Canichess Alumni's tournaments and simuls events.

## Chess Tournaments

- [Swiss system](https://en.wikipedia.org/wiki/Swiss-system_tournament)
  - Tie breakers: Modified median, [Solkoff](https://en.wikipedia.org/wiki/Buchholz_system), Cumulative Score, Cumulative Opponent's score, Number of games played with black pieces
  - Automatic player withdrawal following a configured number consecutive walkover losses.
  - [Bipartite matching](https://www.geeksforgeeks.org/maximum-bipartite-matching/) for a configured number of initial rounds
  - Preferred pairings with rating difference < 400

- Round Robin system
  - Tie breakers: [Sonneborn-Berger](https://en.wikipedia.org/wiki/Sonneborn%E2%80%93Berger_score), Number of wins excluding WO wins, Number of games played with black pieces
- Head to Head (direct) encounters results can be enabled as the first tie breaker, either for swiss or round robin system.

- Pairings and standings pages suitable for videotron output, with real time updates.
- Support for multiple groups in a tournament

## Chess Simultaneous Displays / Exhibitions

- Support for various playing color assignments: all play black, all play white, or alternating color every N boards.
- Total scores and results of each player are updated in real time
- Results page is suitable for videotron output

## Sponsors management

- Add / delete sponsors, assign to tournaments or simul events
- Update logo and URL for each sponsor

## Players Management

- Players' ratings are computed at the end of **rated** tournaments using [Glicko-2 algorithm](https://github.com/proglottis/glicko2)
- Support for tournament or simul players bulk upload, as well as individual input
- Tournaments / simuls players registration supports automatic matching with existing players.
- Support for player labels in a tournament, e.g. junior, senior, or canisian, or any custom prize category

## Current Limitations

- No support for team based tournaments
- A player can only join a single group in a tournament
