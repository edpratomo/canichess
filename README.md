[![Ruby on Rails CI](https://github.com/edpratomo/canichess/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/edpratomo/canichess/actions/workflows/rubyonrails.yml)
[![Docker Image CI](https://github.com/edpratomo/canichess/actions/workflows/docker-image.yml/badge.svg)](https://github.com/edpratomo/canichess/actions/workflows/docker-image.yml)

# Canichess CEO

**Chess Events Organizer** for Canichess Alumni's tournaments and simuls events.

## Chess Tournaments

- Swiss system
  - Tie breakers: Modified median, Solkoff, Cumulative Score, Cumulative    Opponent's score, Number of games played with black pieces
  - Automatic player withdrawal following a configured number consecutive walkover losses.
  - Bipartite matching for a configured number of initial rounds
  - Preferred pairings rating difference < 400

- Round Robin system
  - Tie breakers: Sonneborn-Berger, Number of wins excluding WO wins, Number of games played with black pieces
- Head to Head (direct) encounters points can be enabled as the first tie breaker, either for swiss or round robin system.

- Pairings and standings pages suitable for videotron output, with real time updates.

## Chess Simultaneous Displays / Exhibitions

- Support various playing color assignments: all play black, all play white, or alternating color every n boards.
- Total scores and results of each player are updated in real time
- Results page is suitable for videotron output

## Sponsors management

- Add / delete sponsors, assign to tournaments or simul events
- Update logo and URL for each sponsor

## Players Management

- Players rating are computed at the end of **rated** tournaments
- Supports tournament or simul players bulk upload, as well as individual input
- Support player labels in a tournament
