# golf-comp

A low-cost rudimentary golf competition scoring system using SMS with ClickSend and website hosting with Netlify.

## Prerequisites

* A Unix like command line.
* The latest [npm](https://en.wikipedia.org/wiki/Npm) installed (usually from your standard package manager, e.g. apt).
* The latest [csvkit](https://csvkit.readthedocs.io/en/latest/) for [csvsql](https://csvkit.readthedocs.io/en/latest/scripts/csvsql.html) installed.
* The latest [netlify-cli](https://docs.netlify.com/cli/get-started/) installed.
* Internet access and a browser.
* Willingness to run shell scripts whilst others are enjoying competition.
* Resilience if things go wrong.


## Before a competition

### Days prior

* Setup a ClickSend account [here](https://clicksend.com).
* Setup a Netlify account [here](https://netlify.com).
* Gather the player data into a file named `players.csv` in the `data` folder (see the README in that folder).
* Generate the ClickSend credentials with the shell script within the `src` folder.
* Test by sending a SMS to yourself via a ClickSend campaign then replying with '1 4 2' and again with '2 5 1'.
* Manually run the leaderboard generation and deployment from within your local repository for this project: `src/generate-leaderboard.sh`.
* Check the output on your Netlify site.
* Fix any issues.

### A few days prior

* Test by requesting a few highly cooperative players to send an SMS to the ClickSend number with three whole numbers separated by a single space, a few times with differing numbers.
* Setup a cron job, that runs the deployment every 20 minutes for the competition day, by following these steps at the command line...
    * `crontab -e`
    * Add the following line: `*/20 8-18 * * * ~/repos/golf-comp/src/generate-leaderboard.sh > ~/repos/golf-comp/cronjob.log 2>&1` (change the path to the file to suit you)
* Send an email with content based on the file `instructions-email.txt` in the `comms` folder.
* Send a SMS via a ClickSend campaign with content based on the file `instructions-sms.txt` in the `comms` folder.

### Just prior

* Instruct players to use scorecards and return them at the end of their round as the primary and official way of inclusion in the competition.
* Instruct players to send an SMS to the ClickSend number with the following content for each hole played: hole gross-score stableford-points (e.g. 1 4 2).
* Instruct players to visit your Netlify site to see the leaderboard; refreshing their browser to see updates.


## Roadmap

* TODO Find a way to fully automate for realtime updates, initiated each time a player sends their SMS score.

