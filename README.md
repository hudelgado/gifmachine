gifmachine
==========
*A Machine for Gifs*

- Need an excuse to show a gif to your coworkers? 
- Need a use for that Raspberry Pi that isn't doing anything useful?
- Need a web-scale solution to your animated gif needs?

Presenting the newest GMaaS (Gif Machine as a Service) solution for your tech company with a startup culture: **gifmachine**

![billion dollar startup idea](info/gifmachine-1.gif)

What actually is it?
--------------------
- gifmachine is a Ruby Sinatra app that provides a dirty interface for enjoying gifs with your coworkers. gifmachine provides a HTTP API for posting gifs and meme text to overlay.
- gifmachine allows your coworkers to complain about `company_x`'s broken API when it goes down and laugh as [the internet catches fire](http://istheinternetonfire.com/).
- gifmachine is designed to be run in kiosk mode on an unused computer and monitor, it's just a webpage that puts the gif meme in fullscreen.

How does it work?
-----------------
It mostly does! When it is working well...
- gifmachine uses WebSockets to send out updates to connected clients.
- gifmachine stores everything in a database (developed with Postgres, but it shouldn't be too hard to change that).
- gifmachine uses ActiveRecord to save the developer time and calories.

WebSockets?
-----------
![websockets are magic](info/gifmachine-2.gif)

## Setting up locally with docker compose

1. Ensure docker is available in you system.
2. Copy local environment file `sample.env` to `.env` and adjust it's settings: `cp sample.env .env``
3. Run `docker compose up`
4. In a different terminal initialize the database by running `docker compose exec web sh -c "bundle exec rake db:create; bundle exec rake db:migrate"`
5. Browse to `http://localhost:4567`

## Posting Gifs

Using `curl` you can post a gif and some text to register it in the `gifmachine`

```bash
curl --data 'url=http://www.example.com/somegif.gif&who=thatAmazingPerson&meme_top=herp&meme_bottom=derp&secret=yourSuperSecretPasswordFromAppRb' 'http://yourGifMachineUrl/gif'
```

## Production Architecture

This solution uses ECS Fargate with AWS CodePipelines deployint to ECS.

All of the steps are fully automatic on ECS by using the aws integration.

## Configuring for Production
To run in production, you will need the following:

- Update the `repository_name` variable in the terraform folder code, to ensure is pointing to the correct repository
- Deploy the code and check the application loadbalancer url.
- Give permissions to source code repository connection in aws codepipelines settings.
- Open the application url in browser.
