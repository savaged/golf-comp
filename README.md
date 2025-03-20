# golf-comp

A rudimentary golf competition scoring system using SMS with ClickSend

## Prerequisites

* A Unix like command line.
* Internet access and a browser.
* Willingness to run shell scripts whilst others are enjoying competition.
* Resilience if things go wrong.


## Before a competition

### Days prior

* Setup a ClickSend account [here](https://clicksend.com).
* Setup a Netlify account [here](https://netlify.com).
* Gather the player data into a file named `players.csv` in the `data` folder (see the README in that folder).
* Generate the ClickSend credentials with the shell script within the `src` folder.

### A few days prior

* Test by requesting a few highly cooperative players to send an SMS to the ClickSend number with three whole numbers separated by a single space, a few times with differing numbers.
* Run the 'Deployment Steps' below.
* Send an email with content based on the file `instructions-email.txt` in the `comms` folder.
* Send a SMS via a ClickSend campaign with content based on the file `instructions-sms.txt` in the `comms` folder.

### Just prior

* Instruct players to use scorecards and return them at the end of their round as the primary and official way of inclusion in the competition.
* Instruct players to send an SMS to the ClickSend number with the following content for each hole played: hole gross-score stableford-points (e.g. 1 4 2).
* Instruct players to visit your Netlify site to see the leaderboard; refreshing their browser to see updates.

## During competition

* At regular intervals run the 'Deployment Steps' below.

## Deployment Steps

* Run the shell script `generate-leaderboard.sh` that is within the `src` folder. (i.e. `$ src\generate-leaderboard.sh`).
* Deploy the result by copying the folder named `html` to your Netlify site.

