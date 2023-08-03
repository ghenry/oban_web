defmodule Oban.Web.QueryTest do
  use Oban.Web.Case, async: true

  alias Oban.Config
  alias Oban.Web.{Query, Repo}

  @conf Config.new(repo: Repo)

  describe "parse/1" do
    import Query, only: [parse: 1]

    test "splitting multiple values" do
      assert %{nodes: ["worker-1"]} = parse("nodes:worker-1")
      assert %{queues: ["alpha", "gamma"]} = parse("queues:alpha,gamma")
      assert %{workers: ["My.A", "My.B"]} = parse("workers:My.A,My.B")
      assert %{tags: ["alpha", "gamma"]} = parse("tags:alpha,gamma")
    end

    test "splitting path qualifiers" do
      assert %{args: "Foo"} = parse("args:Foo")
      assert %{args: [~w(account), "Foo"]} = parse("args.account:Foo")
      assert %{args: [~w(account name), "Foo"]} = parse("args.account.name:Foo")
    end
  end

  describe "encode_params/1" do
    import Query, only: [encode_params: 1]

    test "encoding fields with multiple values" do
      assert %{nodes: "web-1,web-2"} = encode_params(nodes: ~w(web-1 web-2))
    end

    test "encoding fields with path qualifiers" do
      assert %{args: "a++x"} = encode_params(args: [~w(a), "x"])
      assert %{args: "a,b++x"} = encode_params(args: [~w(a b), "x"])
      assert %{args: "a,b,c++x"} = encode_params(args: [~w(a b c), "x"])
    end
  end

  describe "decode_params/1" do
    import Query, only: [decode_params: 1]

    test "decoding fields with known integers" do
      assert %{limit: 1} = decode_params(%{"limit" => "1"})
    end

    test "decoding params with multiple values" do
      assert %{nodes: ~w(web-1 web-2)} = decode_params(%{"nodes" => "web-1,web-2"})
      assert %{queues: ~w(alpha gamma)} = decode_params(%{"queues" => "alpha,gamma"})
      assert %{workers: ~w(A B)} = decode_params(%{"workers" => "A,B"})
    end

    test "decoding params with path qualifiers" do
      assert %{args: [~w(a), "x"]} = decode_params(%{"args" => "a++x"})
      assert %{args: [~w(a b), "x"]} = decode_params(%{"args" => "a,b++x"})
      assert %{meta: [~w(a), "x"]} = decode_params(%{"meta" => "a++x"})
    end
  end

  describe "suggest/2" do
    def suggest(terms), do: Query.suggest(terms, @conf)

    test "falling back to defaults without a query" do
      assert [{"args.", _, _} | _] = suggest("")
      assert [{"args.", _, _} | _] = suggest("  ")
    end

    test "falling back to defaults without any fragments" do
      assert [{"args.", _, _} | _] = suggest("priority:1 ")
    end

    test "suggesting qualifiers with fragments" do
      assert [{"priorities:", _, _}] = suggest("prior")
      assert [{"priorities:", _, _}] = suggest("priorities")
    end

    test "ignoring unsuggestable qualifiers" do
      assert [] = suggest("args:")
      assert [] = suggest("args.id:")
      assert [] = suggest("meta:")
      assert [] = suggest("meta.batch_id:")
    end

    test "suggesting fixed priorities" do
      assert [{"0", _, _} | _] = suggest("priorities:")
      assert [{"0", _, _}] = suggest("priorities:0")
      assert [{"1", _, _}] = suggest("priorities:1")
    end

    test "suggesting args" do
      assert [] = suggest("args:")
      assert [] = suggest("args.")
      assert [] = suggest("args.id")

      insert_job!(%{id: 1, account_id: 1})
      insert_job!(%{id: 1, name: "Alpha"})
      insert_job!(%{id: 1, data: %{on: true}})

      assert ~w(account_id data id name) =
               "args."
               |> suggest()
               |> Enum.map(&elem(&1, 0))
               |> Enum.sort()

      assert [{"account_id", _, _}] = suggest("args.accou")
    end

    test "suggesting nested args" do
      insert_job!(%{id: 1, add: %{city: %{name: "Chi", zip: "60647"}, state: "IL"}})
      insert_job!(%{xd: 2, add: %{city: %{name: "Whe", zip: "60187"}, state: "IL"}})

      assert ~w(city state) =
               "args.add."
               |> suggest()
               |> Enum.map(&elem(&1, 0))
               |> Enum.sort()

      assert [{"state", _, _}, _] = suggest("args.add.stat")
      assert [{"name", _, _}] = suggest("args.add.city.nam")
    end

    test "suggesting meta" do
      assert [] = suggest("meta:")
      assert [] = suggest("meta.")
      assert [] = suggest("meta.batch_id")

      insert_job!(%{}, meta: %{id: 1, account_id: 1})
      insert_job!(%{}, meta: %{id: 1, name: "Alpha"})
      insert_job!(%{}, meta: %{id: 1, data: %{on: true}})

      assert ~w(account_id data id name) =
               "meta."
               |> suggest()
               |> Enum.map(&elem(&1, 0))
               |> Enum.sort()

      assert [{"account_id", _, _}] = suggest("meta.accou")
    end

    test "suggesting nodes" do
      assert [] = suggest("nodes:")

      insert_job!(%{}, attempted_by: ["web.1@host", "abc-123"])
      insert_job!(%{}, attempted_by: ["web.2@host", "abc-123"])
      insert_job!(%{}, attempted_by: ["loc.8@host", "abc-123"])

      assert [{"loc.8@host", _, _}, _, _] = suggest("nodes:")
      assert [{"web.1@host", _, _}, {"web.2@host", _, _}] = suggest("nodes:web")
      assert [{"web.1@host", _, _}, _] = suggest("nodes:web.1")
    end

    test "suggesting queues" do
      assert [] = suggest("queues:")

      insert_job!(%{}, queue: "alpha")
      insert_job!(%{}, queue: "gamma")
      insert_job!(%{}, queue: "delta")

      assert [{"alpha", _, _}, _, _] = suggest("queues:")
      assert [{"alpha", _, _}] = suggest("queues:alph")
      assert [{"delta", _, _}, _] = suggest("queues:delta")
    end

    test "suggesting tags" do
      assert [] = suggest("tags:")

      insert_job!(%{}, tags: ~w(alpha gamma))
      insert_job!(%{}, tags: ~w(gamma delta))
      insert_job!(%{}, tags: ~w(delta))

      assert ~w(alpha delta gamma) =
               "tags:"
               |> suggest()
               |> Enum.map(&elem(&1, 0))
               |> Enum.sort()

      assert [{"delta", _, _}] = suggest("tags:de")
    end

    test "suggesting workers" do
      assert [] = suggest("workers:")

      insert_job!(%{}, worker: MyApp.Alpha)
      insert_job!(%{}, worker: MyApp.Gamma)
      insert_job!(%{}, worker: MyApp.Delta)

      assert [{"MyApp.Alpha", _, _}, _, _] = suggest("workers:")
      assert [{"MyApp.Alpha", _, _}, _, _] = suggest("workers:My")
      assert [{"MyApp.Delta", _, _}] = suggest("workers:Delta")
    end

    test "suggesting with a resolver that implements hint_query_limit/1" do
      defmodule HintResolver do
        def hint_query_limit(:workers), do: 1
        def hint_query_limit(_qualifier), do: :infinity
      end

      insert_job!(%{}, queue: :alpha, worker: MyApp.Alpha)
      insert_job!(%{}, queue: :gamma, worker: MyApp.Gamma)
      insert_job!(%{}, queue: :delta, worker: MyApp.Delta)

      assert [_, _] = Query.suggest("workers:", @conf, resolver: HintResolver)
      assert [_, _, _] = Query.suggest("queues:", @conf, resolver: HintResolver)
    end
  end

  describe "complete/2" do
    def complete(terms) do
      Query.complete(terms, @conf)
    end

    test "completing with an unknown qualifier" do
      assert "stuff" == complete("stuff")
    end

    test "completing a qualifier" do
      assert "queues:" == complete("qu")
      assert "queues:" == complete("queue")
    end

    test "completing a path qualifier" do
      insert_job!(%{id: 1, account_id: 1})

      assert "args.id" == complete("args.i")
      assert "args.account_id" == complete("args.accou")
    end
  end

  describe "append/2" do
    import Query, only: [append: 2]

    test "appending new qualifiers" do
      assert "queue:" == append("qu", "queue:")
      assert "queue:" == append("queue", "queue:")
      assert "queue:" == append("queue:", "queue:")
      assert "args." == append("arg", "args.")
    end

    test "preventing duplicate values" do
      assert "queue:" == append("queue:", "queue:")
    end
  end

  describe "all_jobs/2" do
    test "filtering by node" do
      insert_job!(%{ref: 1}, attempted_by: ["worker.1", "abc-123"])
      insert_job!(%{ref: 2}, attempted_by: ["worker.2", "abc-123"])

      assert [1] = filter_refs(nodes: ~w(worker.1))
      assert [2] = filter_refs(nodes: ~w(worker.2))
      assert [1, 2] = filter_refs(nodes: ~w(worker.1 worker.2))
      assert [] = filter_refs(nodes: ~w(web.1))
    end

    test "filtering by priority" do
      insert_job!(%{ref: 0}, priority: 0)
      insert_job!(%{ref: 1}, priority: 1)
      insert_job!(%{ref: 2}, priority: 2)

      assert [0] = filter_refs(priorities: ~w(0))
      assert [0, 1] = filter_refs(priorities: ~w(0 1))
      assert [0, 1, 2] = filter_refs(priorities: ~w(0 1 2 3))
      assert [] = filter_refs(priorities: ~w(3))
    end

    test "filtering by queue" do
      insert_job!(%{ref: 1}, queue: "alpha")
      insert_job!(%{ref: 2}, queue: "gamma")

      assert [1] = filter_refs(queues: ~w(alpha))
      assert [2] = filter_refs(queues: ~w(gamma))
      assert [1, 2] = filter_refs(queues: ~w(alpha gamma))
      assert [] = filter_refs(queues: ~w(delta))
    end

    test "constraining by state" do
      insert_job!(%{ref: 0}, state: "available")
      insert_job!(%{ref: 1}, state: "available")
      insert_job!(%{ref: 2}, state: "scheduled")
      insert_job!(%{ref: 3}, state: "completed")

      assert [0, 1] = filter_refs(state: "available")
      assert [] = filter_refs(state: "executing")
    end

    test "filtering by tags" do
      insert_job!(%{ref: 0}, tags: ["audio"])
      insert_job!(%{ref: 1}, tags: ["audio", "video"])
      insert_job!(%{ref: 2}, tags: ["video"])

      assert [0, 1] = filter_refs(tags: ~w(audio))
      assert [1, 2] = filter_refs(tags: ~w(video))
      assert [0, 1, 2] = filter_refs(tags: ~w(audio video))
      assert [0, 1] = filter_refs(tags: ~w(audio nada))
      assert [] = filter_refs(tags: ~w(nada))
    end

    test "filtering by worker" do
      insert_job!(%{ref: 1}, worker: MyApp.VideoA)
      insert_job!(%{ref: 2}, worker: MyApp.VideoB)

      assert [1] = filter_refs(workers: ~w(MyApp.VideoA))
      assert [2] = filter_refs(workers: ~w(MyApp.VideoB))
      assert [1, 2] = filter_refs(workers: ~w(MyApp.VideoA MyApp.VideoB))
      assert [] = filter_refs(workers: ~w(MyApp.Video))
    end

    test "searching within args" do
      insert_job!(%{ref: 0, mode: "video", domain: "myapp"})
      insert_job!(%{ref: 1, mode: "audio", domain: "myapp"})
      insert_job!(%{ref: 2, mode: "multi", domain: "myapp"})

      assert [0] = filter_refs(args: "video")
      assert [1] = filter_refs(args: "audio")
      assert [0, 1, 2] = filter_refs(args: "myapp")
      assert [0, 1] = filter_refs(args: "video or audio")
      assert [] = filter_refs(args: "nada")
    end

    test "searching within args sub-fields" do
      insert_job!(%{ref: 0, mode: "audio", bar: %{baz: 1}})
      insert_job!(%{ref: 1, mode: "video", bar: %{baz: 2}})
      insert_job!(%{ref: 2, mode: "media", bar: %{bat: 3}})

      assert [0] = filter_refs(args: [~w(mode), "audio"])
      assert [1] = filter_refs(args: [~w(mode), "video"])
      assert [0, 1] = filter_refs(args: [~w(mode), "audio or video"])

      assert [0] = filter_refs(args: [~w(bar baz), "1"])
      assert [0, 1] = filter_refs(args: [~w(bar), "baz"])
      assert [2] = filter_refs(args: [~w(bar bat), "3"])
      assert [] = filter_refs(args: [~w(bar bat), "4"])
    end

    test "searching within meta" do
      insert_job!(%{ref: 0}, meta: %{mode: "video", domain: "myapp"})
      insert_job!(%{ref: 1}, meta: %{mode: "audio", domain: "myapp"})
      insert_job!(%{ref: 2}, meta: %{mode: "multi", domain: "myapp"})

      assert [0] = filter_refs(meta: "video")
      assert [1] = filter_refs(meta: "audio")
      assert [0, 1, 2] = filter_refs(meta: "myapp")
      assert [0, 1] = filter_refs(meta: "video or audio")
      assert [] = filter_refs(meta: "nada")
    end

    test "searching within meta sub-fields" do
      insert_job!(%{ref: 0}, meta: %{mode: "audio", bar: %{baz: 1}})
      insert_job!(%{ref: 1}, meta: %{mode: "video", bar: %{baz: 2}})
      insert_job!(%{ref: 2}, meta: %{mode: "media", bar: %{bat: 3}})

      assert [0] = filter_refs(meta: [~w(mode), "audio"])
      assert [1] = filter_refs(meta: [~w(mode), "video"])
      assert [0, 1] = filter_refs(meta: [~w(mode), "audio or video"])

      assert [0] = filter_refs(meta: [~w(bar baz), "1"])
      assert [0, 1] = filter_refs(meta: [~w(bar), "baz"])
      assert [2] = filter_refs(meta: [~w(bar bat), "3"])
      assert [] = filter_refs(meta: [~w(bar bat), "4"])
    end

    test "ignoring the meta recorded column" do
      insert_job!(%{ref: 1}, meta: %{recorded: "video"})
      insert_job!(%{ref: 2}, meta: %{searched: "video"})

      assert [2] = filter_refs(meta: "video")
    end

    test "negating search terms" do
      insert_job!(%{ref: 0, mode: "video"})
      insert_job!(%{ref: 1, mode: "audio"})
      insert_job!(%{ref: 2}, meta: %{mode: "video"})
      insert_job!(%{ref: 3}, meta: %{mode: "audio"})

      assert [1, 2, 3] = filter_refs(args: "-video")
      assert [0, 1, 3] = filter_refs(meta: "-video")
    end

    test "filtering by multiple terms" do
      insert_job!(%{ref: 0, mode: "video"}, worker: Media, meta: %{batch_id: 1})
      insert_job!(%{ref: 1, mode: "audio"}, worker: Media, meta: %{batch_id: 1})
      insert_job!(%{ref: 2, mode: "multi"}, worker: Media, meta: %{batch_id: 2})

      assert [0] = filter_refs(workers: ~w(Media), args: "video", meta: [~w(batch_id), "1"])
      assert [1] = filter_refs(workers: ~w(Media), args: "audio", meta: [~w(batch_id), "1"])
      assert [2] = filter_refs(args: "multi", meta: [~w(batch_id), "2"])
      assert [] = filter_refs(args: "audio", meta: [~w(batch_id), "2"])
    end

    test "ordering fields by state" do
      ago = fn sec -> DateTime.add(DateTime.utc_now(), -sec) end

      job_a = insert_job!(%{}, state: "cancelled", cancelled_at: ago.(4))
      job_b = insert_job!(%{}, state: "cancelled", cancelled_at: ago.(6))
      job_c = insert_job!(%{}, state: "cancelled", cancelled_at: ago.(1))

      assert [job_b.id, job_a.id, job_c.id] ==
               @conf
               |> Query.all_jobs(%{state: "cancelled"})
               |> Enum.map(& &1.id)

      assert [job_c.id, job_a.id, job_b.id] ==
               @conf
               |> Query.all_jobs(%{state: "cancelled", sort_dir: "desc"})
               |> Enum.map(& &1.id)
    end

    test "restrict the query with a resolver that implements jobs_query_limit/1" do
      defmodule JobResolver do
        def jobs_query_limit(:completed), do: 1
        def jobs_query_limit(:executing), do: 10
      end

      insert_job!(%{ref: 0}, state: "executing")
      insert_job!(%{ref: 1}, state: "executing")
      insert_job!(%{ref: 2}, state: "executing")
      insert_job!(%{ref: 3}, state: "completed")
      insert_job!(%{ref: 4}, state: "completed")
      insert_job!(%{ref: 5}, state: "completed")

      assert [0, 1, 2] = filter_refs(%{state: "executing"}, resolver: JobResolver)
      assert [4, 5] = filter_refs(%{state: "completed"}, resolver: JobResolver)
    end
  end

  defp filter_refs(params, opts \\ []) do
    params =
      params
      |> Map.new()
      |> Map.put_new(:state, "available")

    params
    |> Query.all_jobs(@conf, opts)
    |> Enum.map(& &1.args["ref"])
    |> Enum.sort()
  end
end
