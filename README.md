# ObanWeb

A live dashboard for monitoring and operating Oban.

## Installation (For Development)

Using ObanWeb from another application in development mode requires a little
maneuvering. While you can specify `oban_web` as a path dependency, that doesn't
work with Phoenix's code reloading features. During development I suggest the
following work-flow:

Switching to Development

1. In `mix.exs` comment out `oban_web`
2. Create symlinks from `oban_web` into the `lib` directory of your primary app

I recommend automating the steps with a make task, as this is something you'll
do often. This command will automate linking local `oban_web`:

```make
relink-oban-web:
	sed -i '' '/:oban_web/ s/\(.*\)\({.*\)/\1# \2/' mix.exs && \
	cd lib && \
	ln -fs ../../oban_web/lib/oban_web ./oban_web && \
	ln -fs ../../oban_web/lib/oban_web.ex ./oban_web.ex
```

And this command to switch back to the published version:

```make
unlink-oban-web:
	sed -i '' '/:oban_web/ s/\(.*\)# \(.*\)/\1\2/' mix.exs && \
	rm lib/oban_web* && \
	mix deps.update oban_web
```

## Installation (From a Package)

This project relies on a working install of Oban as well as Phoenix.

1. Install [Phoenix Live View][plv]

2. Authenticate with the `oban` [organization on hex][hpm], this is required to
   pull down the `ObanWeb` package locally and in CI.

3. Add `ObanWeb` as a dependency in your `mix.exs` file:

  ```
  {:oban_web, "~> 1.0", organization: "oban"}
  ```

4. Add `ObanWeb` as a child within your application module:

  ```
  def start(_type, _args) do
    oban_opts = Application.get_env(:my_app, Oban)
    oban_web_opts = Application.get_env(:my_app, ObanWeb)

    children = [
      MyApp.Repo,
      MyApp.Endpoint,
      {Oban, oban_opts},
      {ObanWeb, oban_web_opts}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]

    Supervisor.start_link(children, opts)
  end
  ```

5. Mount the dashboard within your Phoenix router:

  ```
  scope "/" do
    pipe_through :browser

    live "/oban", ObanWeb.DashboardLive, layout: {ObanWeb.LayoutView, "app.html"}
  end
  ```

  Here we're using `"/oban"` as the mount point, but it can be anywhere you like.

6. Run `ObanWeb` migrations to create indexes and setup notifications:

  ```
  defmodule MyApp.Repo.Migrations.UpgradeObanWeb do
    use Ecto.Migration

    defdelegate up, to: ObanWeb.Migrations
    defdelegate down, to: ObanWeb.Migrations
  end
  ```

7. Optionally increase the search tolerance for full text queries by setting an
   `after_connect` hook on your repo:

  ```
  after_connect: {Postgrex, :query!, ["SELECT set_limit($1)", [0.1]]}
  ```

[plv]: https://github.com/phoenixframework/phoenix_live_view#installation
[hpm]: https://hex.pm/docs/private#authenticating-on-ci-and-build-servers

## Contributing

Working on ObanWeb has the following dependencies:

1. Elixir 1.8+
2. Erlang/OTP 21.0+
3. Postgres 10+
4. Node (for [parcel](https://parceljs.org/))
5. Brew (for fswatch and [sassc](https://github.com/sass/sassc))

We'll assume you have Elixir/Erlang/PostgreSQL running already (because you
wouldn't be reading this otherwise!). To install the remaining dependencies run
`make prepare`. That will install `fswatch`, `sassc`, `parcel` and fetch `mix
deps`

#### Update Assets

Run `make watch` when you need to change js or css assets. That will take care
of:

1. `make js` to bundle the latest phoenix and live view js
2. `make css` to compile scss
3. `make watch_loop` to start the css compilation loop

The compilation loop ensures that the css assets are compiled and stay up
to date. The js asset(s) are only compiled once, when the loop starts. These
don't change very often and are much slower to build.

#### Tests & Code Quality

To ensure a commit passes CI you should run `MIX_ENV=test mix ci` locally, which
executes the following commands:

* Check formatting (`mix format --check-formatted`)
* Lint with Credo (`mix credo --strict`)
* Run all tests (`mix test --raise`)
