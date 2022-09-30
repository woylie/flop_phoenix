defmodule Flop.Phoenix.FormDataTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.HTML.Form
  import Flop.Phoenix.Factory
  import Flop.Phoenix.ViewHelpers

  alias Flop.Filter
  alias Flop.Phoenix.Pet
  alias Phoenix.HTML.Form

  describe "form_for/3" do
    test "with meta struct" do
      meta = build(:meta_on_first_page, errors: [limit: [{"whatever", nil}]])

      html =
        form_to_html(meta, fn f ->
          assert f.data == meta.flop
          assert f.errors == meta.errors
          assert f.params == %{}
          assert f.source == meta
          ""
        end)

      assert [{"form", [{"action", "/"}, {"method", "post"}], _}] = html
    end

    test "with :as" do
      form_to_html(build(:meta_on_first_page), [as: :flop], fn f ->
        assert f.name == "flop"
        assert f.id == "flop"
        ""
      end)
    end

    test "with :id" do
      meta = build(:meta_on_first_page)
      opts = [id: "flip", as: :flop]

      html =
        form_to_html(meta, opts, fn f ->
          assert f.name == "flop"
          assert f.id == "flip"
          ""
        end)

      assert [
               {"form", [{"action", "/"}, {"id", "flip"}, {"method", "post"}],
                _}
             ] = html
    end

    test "with hidden inputs" do
      meta = build(:meta_on_first_page)

      html =
        form_to_html(meta, fn f ->
          assert f.hidden == [page_size: meta.flop.page_size]
          hidden_inputs_for(f)
        end)

      assert [input] = Floki.find(html, "input#flop_page_size")
      assert Floki.attribute(input, "name") == ["page_size"]
      assert Floki.attribute(input, "value") == ["#{meta.flop.page_size}"]

      meta = build(:meta_on_first_page, flop: %Flop{limit: 15, page_size: nil})
      %Form{hidden: [limit: 15]} = form_for(meta, "/")

      meta = build(:meta_on_first_page, flop: %Flop{first: 20})
      %Form{hidden: [first: 20]} = form_for(meta, "/")

      meta = build(:meta_on_first_page, flop: %Flop{last: 25})
      %Form{hidden: [last: 25]} = form_for(meta, "/")
    end

    test "omits hidden inputs if the value matches default" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            first: 20,
            last: 20,
            limit: 20,
            page_size: 20,
            order_by: [:name],
            order_directions: [:asc]
          },
          schema: Pet
        )

      form_to_html(meta, fn f ->
        assert f.hidden == []
        ""
      end)
    end

    test "with hidden inputs for order" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{order_by: [:name, :age], order_directions: [:desc, :asc]}
        )

      assigns = %{meta: meta}

      html =
        parse_heex(~H"""
        <.form :let={f} for={@meta}>
          <Flop.Phoenix.hidden_inputs_for_filter form={f} />
        </.form>
        """)

      assert [input] = Floki.find(html, "input#flop_order_by_0")
      assert Floki.attribute(input, "name") == ["order_by[]"]
      assert Floki.attribute(input, "value") == ["name"]

      assert [input] = Floki.find(html, "input#flop_order_by_1")
      assert Floki.attribute(input, "name") == ["order_by[]"]
      assert Floki.attribute(input, "value") == ["age"]

      assert [input] = Floki.find(html, "input#flop_order_directions_0")
      assert Floki.attribute(input, "name") == ["order_directions[]"]
      assert Floki.attribute(input, "value") == ["desc"]

      assert [input] = Floki.find(html, "input#flop_order_directions_1")
      assert Floki.attribute(input, "name") == ["order_directions[]"]
      assert Floki.attribute(input, "value") == ["asc"]
    end

    test "with additional hidden inputs" do
      meta = build(:meta_on_first_page)
      opts = [hidden: [something: "else"]]
      html = form_to_html(meta, opts, fn f -> hidden_inputs_for(f) end)
      assert [_] = Floki.find(html, "input#flop_page_size")
      assert [input] = Floki.find(html, "input#flop_something")
      assert Floki.attribute(input, "name") == ["something"]
      assert Floki.attribute(input, "value") == ["else"]
    end
  end

  describe "form_for/4" do
    test "with filters" do
      %{flop: %{filters: [filter]}} =
        meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :like, value: "George"}]
          }
        )

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, fn fo ->
            assert fo.data == filter
            assert fo.hidden == [op: :like, field: :name]
            assert fo.id == "flop_filters_0"
            assert fo.index == 0
            assert fo.name == "filters[0]"
            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_field")
      assert Floki.attribute(input, "name") == ["filters[0][field]"]
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["name"]

      assert [input] = Floki.find(html, "input#flop_filters_0_op")
      assert Floki.attribute(input, "name") == ["filters[0][op]"]
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["like"]

      assert [input] = Floki.find(html, "input#flop_filters_0_value")
      assert Floki.attribute(input, "name") == ["filters[0][value]"]
      assert Floki.attribute(input, "type") == ["text"]
      assert Floki.attribute(input, "value") == ["George"]
    end

    @tag capture_log: true
    test "with filters and errors" do
      invalid_params = %{
        page: 0,
        filters: [
          %{field: :name, op: :like, value: "George"},
          %{field: "age", op: "<>", value: "8"},
          %{field: :species, value: "dog"}
        ]
      }

      {:error, meta} = Flop.validate(invalid_params)

      html =
        form_to_html(meta, fn f ->
          assert f.data == %Flop{}

          assert f.params == %{
                   "filters" => [
                     %{"field" => :name, "op" => :like, "value" => "George"},
                     %{"field" => "age", "op" => "<>", "value" => "8"},
                     %{"field" => :species, "value" => "dog"}
                   ],
                   "page" => 0
                 }

          assert [{"must be greater than %{number}", _}] =
                   Keyword.get(f.errors, :page)

          inputs_for(f, :filters, fn fo ->
            case fo.id do
              "flop_filters_0" ->
                assert fo.data == %Filter{}

                assert fo.params == %{
                         "field" => :name,
                         "op" => :like,
                         "value" => "George"
                       }

                assert fo.errors == []

              "flop_filters_1" ->
                assert fo.data == %Filter{}

                assert fo.params == %{
                         "field" => "age",
                         "op" => "<>",
                         "value" => "8"
                       }

                assert [op: [{"is invalid", _}]] = fo.errors

              "flop_filters_2" ->
                assert fo.data == %Filter{}

                assert fo.params == %{
                         "field" => :species,
                         "value" => "dog"
                       }

                assert fo.errors == []
            end

            text_input(fo, :value)
          end)
        end)

      assert [_] = Floki.find(html, "input#flop_filters_0_value")
      assert [_] = Floki.find(html, "input#flop_filters_1_value")
      assert [_] = Floki.find(html, "input#flop_filters_2_value")
    end

    test "with filters and without errors" do
      valid_params = %{
        page: 2,
        page_size: 10,
        filters: [
          %{field: :name, op: :like, value: "George"},
          %{field: :age, op: :==, value: 8},
          %{field: :species, value: "dog"}
        ]
      }

      {:ok, flop} = Flop.validate(valid_params)
      meta = build(:meta_on_first_page, flop: flop)

      html =
        form_to_html(meta, fn f ->
          assert f.errors == []

          inputs_for(f, :filters, fn fo ->
            assert fo.errors == []
            text_input(fo, :value)
          end)
        end)

      assert [_] = Floki.find(html, "input#flop_filters_0_value")
      assert [_] = Floki.find(html, "input#flop_filters_1_value")
      assert [_] = Floki.find(html, "input#flop_filters_2_value")
    end

    test "with filters and :default option" do
      meta = build(:meta_on_first_page, flop: %Flop{filters: []})

      html =
        form_to_html(meta, fn f ->
          inputs_for(
            f,
            :filters,
            [default: [%Filter{field: :name, op: :!=}]],
            fn fo ->
              assert fo.data == %Filter{field: :name, op: :!=, value: nil}
              assert fo.hidden == [op: :!=, field: :name]
              assert fo.id == "flop_filters_0"
              assert fo.index == 0
              assert fo.name == "filters[0]"
              text_input(fo, :value)
            end
          )
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_field")
      assert Floki.attribute(input, "name") == ["filters[0][field]"]
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["name"]

      assert [input] = Floki.find(html, "input#flop_filters_0_op")
      assert Floki.attribute(input, "name") == ["filters[0][op]"]
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["!="]

      assert [input] = Floki.find(html, "input#flop_filters_0_value")
      assert Floki.attribute(input, "name") == ["filters[0][value]"]
      assert Floki.attribute(input, "type") == ["text"]
      assert Floki.attribute(input, "value") == []
    end

    test "with :fields option" do
      meta = build(:meta_on_first_page, flop: %Flop{filters: []})

      opts = [fields: [:name, :age]]

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, opts, fn fo ->
            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_field")
      assert Floki.attribute(input, "value") == ["name"]

      assert [input] = Floki.find(html, "input#flop_filters_1_field")
      assert Floki.attribute(input, "value") == ["age"]

      assert [] = Floki.find(html, "input#flop_filters_2_field")
    end

    test "with :fields option and existing filters" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [
              %Filter{field: :species, value: :dog},
              %Filter{field: :name, op: :!=, value: "Peter"},
              %Filter{field: "name", value: "George"},
              %Filter{field: :age, op: :>, value: 8}
            ]
          }
        )

      opts = [fields: [:name, :age]]

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, opts, fn fo ->
            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_field")
      assert Floki.attribute(input, "value") == ["name"]
      assert [input] = Floki.find(html, "input#flop_filters_0_value")
      assert Floki.attribute(input, "value") == ["George"]

      assert [input] = Floki.find(html, "input#flop_filters_1_field")
      assert Floki.attribute(input, "value") == ["age"]
      assert [input] = Floki.find(html, "input#flop_filters_1_value")
      assert Floki.attribute(input, "value") == []

      assert [] = Floki.find(html, "input#flop_filters_2_field")
    end

    @tag capture_log: true
    test "with :fields option and errors" do
      invalid_params = %{
        filters: [
          %{field: :species, value: :dog},
          %{field: :name, value: "Peter"},
          %{field: :name, value: "George"},
          %{field: :age, op: :roundabout, value: 8},
          %{field: :age, op: :>, value: 8}
        ]
      }

      {:error, meta} = Flop.validate(invalid_params)

      opts = [fields: [{:age, op: :>}, :name]]

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, opts, fn fo ->
            case fo.id do
              "flop_filters_0" ->
                assert fo.data == %Filter{}
                assert fo.params == %{"field" => :age, "op" => :>, "value" => 8}
                assert fo.errors == []

              "flop_filters_1" ->
                assert fo.data == %Filter{}
                assert fo.params == %{"field" => :name, "value" => "Peter"}
                assert fo.errors == []
            end

            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_field")
      assert Floki.attribute(input, "value") == ["age"]
      assert [input] = Floki.find(html, "input#flop_filters_0_value")
      assert Floki.attribute(input, "value") == ["8"]

      assert [input] = Floki.find(html, "input#flop_filters_1_field")
      assert Floki.attribute(input, "value") == ["name"]
      assert [input] = Floki.find(html, "input#flop_filters_1_value")
      assert Floki.attribute(input, "value") == ["Peter"]
    end

    @tag capture_log: true
    test "does not reject filterable fields when fields are strings" do
      invalid_params = %{
        "filters" => [
          %{"field" => "name", "op" => "ilike_and", "value" => ""},
          %{"field" => "age", "value" => ""}
        ],
        "page" => "0"
      }

      {:error, meta} = Flop.validate(invalid_params, for: Pet)
      opts = [fields: [age: [label: "Age"], name: [op: :ilike_and]]]

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, opts, fn fo ->
            case fo.id do
              "flop_filters_0" ->
                assert fo.data == %Filter{}
                assert fo.params == %{"field" => "age", "value" => ""}
                assert fo.errors == []

              "flop_filters_1" ->
                assert fo.data == %Filter{}

                assert fo.params == %{
                         "field" => "name",
                         "value" => "",
                         "op" => "ilike_and"
                       }

                assert fo.errors == []
            end

            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_field")
      assert Floki.attribute(input, "value") == ["age"]
      assert [input] = Floki.find(html, "input#flop_filters_0_value")
      assert Floki.attribute(input, "value") == [""]

      assert [input] = Floki.find(html, "input#flop_filters_1_field")
      assert Floki.attribute(input, "value") == ["name"]
      assert [input] = Floki.find(html, "input#flop_filters_1_value")
      assert Floki.attribute(input, "value") == [""]
    end

    test "with :fields and :op option" do
      meta = build(:meta_on_first_page, flop: %Flop{filters: []})
      opts = [fields: [:name, {:age, op: :>}]]

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, opts, fn fo ->
            hidden_inputs_for(fo)
            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_1_field")
      assert Floki.attribute(input, "value") == ["age"]
      assert [input] = Floki.find(html, "input#flop_filters_1_op")
      assert Floki.attribute(input, "value") == [">"]
    end

    test "with :fields and :default option" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{filters: [%Filter{field: :age, op: :>=, value: 10}]}
        )

      opts = [fields: [{:name, default: "George"}, {:age, op: :>=, default: 8}]]

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, opts, fn fo ->
            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_field")
      assert Floki.attribute(input, "value") == ["name"]
      assert [input] = Floki.find(html, "input#flop_filters_0_value")
      assert Floki.attribute(input, "value") == ["George"]

      assert [input] = Floki.find(html, "input#flop_filters_1_field")
      assert Floki.attribute(input, "value") == ["age"]
      assert [input] = Floki.find(html, "input#flop_filters_1_value")
      assert Floki.attribute(input, "value") == ["10"]
    end

    test "with filters and :id option" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :like, value: "George"}]
          }
        )

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, [id: "f1ltah"], fn fo ->
            assert fo.id == "f1ltah_filters_0"
            assert fo.index == 0
            assert fo.name == "filters[0]"
            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#f1ltah_filters_0_field")
      assert Floki.attribute(input, "name") == ["filters[0][field]"]

      assert [input] = Floki.find(html, "input#f1ltah_filters_0_op")
      assert Floki.attribute(input, "name") == ["filters[0][op]"]

      assert [input] = Floki.find(html, "input#f1ltah_filters_0_value")
      assert Floki.attribute(input, "name") == ["filters[0][value]"]
    end

    test "with filters and :name option on outer form" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :like, value: "George"}]
          }
        )

      html =
        form_to_html(meta, [as: "f1ltah"], fn f ->
          inputs_for(f, :filters, fn fo ->
            assert fo.id == "f1ltah_filters_0"
            assert fo.name == "f1ltah[filters][0]"
            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#f1ltah_filters_0_field")
      assert Floki.attribute(input, "name") == ["f1ltah[filters][0][field]"]

      assert [input] = Floki.find(html, "input#f1ltah_filters_0_op")
      assert Floki.attribute(input, "name") == ["f1ltah[filters][0][op]"]

      assert [input] = Floki.find(html, "input#f1ltah_filters_0_value")
      assert Floki.attribute(input, "name") == ["f1ltah[filters][0][value]"]
    end

    test "with filters and without hidden input for :op" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :like, value: "George"}]
          }
        )

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, [skip_hidden_op: true], fn fo ->
            assert fo.hidden == [field: :name]
            [text_input(fo, :op), text_input(fo, :value)]
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_op")
      assert Floki.attribute(input, "name") == ["filters[0][op]"]
      assert Floki.attribute(input, "type") == ["text"]
      assert Floki.attribute(input, "value") == ["like"]
    end

    test "omits hidden input for default :op (:==)" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :==, value: "George"}]
          }
        )

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, [], fn fo ->
            assert fo.hidden == [{:field, :name}]
            ""
          end)
        end)

      assert [] = Floki.find(html, "input#flop_filters_0_op")
    end

    test "omits fields that are not filterable" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [
              %Filter{field: :age, op: :>=, value: 10},
              %Filter{field: :species, op: :==, value: "dog"}
            ]
          },
          schema: Pet
        )

      opts = [fields: [:species, :age, :specialty]]

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, opts, fn fo ->
            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_field")
      assert Floki.attribute(input, "value") == ["age"]
      assert [] = Floki.find(html, "input#flop_filters_1_field")
      assert [] = Floki.find(html, "input#flop_filters_2_field")
    end

    @tag capture_log: true
    test "omits fields that are not filterable with string params" do
      params = %{
        "page" => 0,
        "filters" => [
          %{"field" => :age, "op" => :>=, "value" => 10},
          %{"field" => :species, "op" => :==, "value" => "dog"}
        ]
      }

      {:error, meta} = Flop.validate(params, for: Pet)
      opts = [fields: [:species, :age, :specialty]]

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, opts, fn fo ->
            text_input(fo, :value)
          end)
        end)

      assert [input] = Floki.find(html, "input#flop_filters_0_field")
      assert Floki.attribute(input, "value") == ["age"]
      assert [] = Floki.find(html, "input#flop_filters_1_field")
      assert [] = Floki.find(html, "input#flop_filters_2_field")
    end

    test "raises error with unsupported options" do
      meta = build(:meta_on_first_page)

      for opt <- [:hidden, :as, :append, :prepend] do
        msg = ":#{opt} is not supported on inputs_for with Flop.Meta."

        assert_raise ArgumentError, msg, fn ->
          form_to_html(meta, fn f ->
            inputs_for(f, :filters, [{opt, :whatever}], fn _ -> "" end)
          end)
        end
      end
    end

    test "with unknown fields" do
      meta = build(:meta_on_first_page)

      msg =
        "Only :filters is supported on " <>
          "inputs_for with Flop.Meta, got: :something."

      assert_raise ArgumentError, msg, fn ->
        form_to_html(meta, fn f ->
          inputs_for(f, :something, fn _ -> "" end)
        end)
      end
    end
  end

  describe "input_type/2" do
    test "returns input type depending on field" do
      form_to_html(build(:meta_on_first_page), fn f ->
        assert input_type(f, :after) == :text_input
        assert input_type(f, :before) == :text_input
        assert input_type(f, :first) == :number_input
        assert input_type(f, :last) == :number_input
        assert input_type(f, :limit) == :number_input
        assert input_type(f, :offset) == :number_input
        assert input_type(f, :page) == :number_input
        assert input_type(f, :page_size) == :number_input
        assert input_type(f, :anything_else) == :text_input
        ""
      end)
    end

    test "returns text_input for filter fields if no schema is passed" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{filters: [%Filter{field: :name, op: :>=, value: "a"}]}
        )

      form_to_html(meta, fn f ->
        inputs_for(f, :filters, fn fo ->
          assert input_type(fo, :field) == :text_input
          assert input_type(fo, :op) == :text_input
          assert input_type(fo, :value) == :text_input
          ""
        end)
      end)
    end

    test "returns input type depending on schema field type" do
      mapping = [
        integer: :number_input,
        float: :text_input,
        boolean: :checkbox,
        string: :text_input,
        decimal: :text_input,
        date: :date_select,
        time: :time_select,
        time_usec: :time_select,
        naive_datetime: :datetime_select,
        naive_datetime_usec: :datetime_select,
        utc_datetime: :datetime_select,
        utc_datetime_usec: :datetime_select
      ]

      filters = mapping |> Keyword.keys() |> Enum.map(&%Filter{field: &1})

      meta =
        build(:meta_on_first_page,
          flop: %Flop{filters: filters},
          schema: __MODULE__.TestSchema
        )

      form_to_html(meta, fn f ->
        inputs_for(f, :filters, fn fo ->
          field = input_value(fo, :field)
          expected = Keyword.fetch!(mapping, field)
          assert input_type(fo, :field) == :text_input
          assert input_type(fo, :op) == :text_input
          assert input_type(fo, :value) == expected
          ""
        end)
      end)
    end
  end

  defmodule TestSchema do
    use Ecto.Schema

    @derive {
      Flop.Schema,
      filterable: [
        :integer,
        :float,
        :boolean,
        :string,
        :decimal_field,
        :date,
        :time,
        :time_usec,
        :naive_datetime,
        :naive_datetime_usec,
        :utc_datetime,
        :utc_datetime_usec
      ],
      sortable: []
    }

    schema "test_schema" do
      field(:integer, :integer)
      field(:float, :float)
      field(:boolean, :boolean)
      field(:string, :string)
      field(:decimal_field, :decimal)
      field(:date, :date)
      field(:time, :time)
      field(:time_usec, :time_usec)
      field(:naive_datetime, :naive_datetime)
      field(:naive_datetime_usec, :naive_datetime_usec)
      field(:utc_datetime, :utc_datetime)
      field(:utc_datetime_usec, :utc_datetime_usec)
    end
  end

  describe "input_validations/3" do
    test "returns validations depending on field" do
      form_to_html(build(:meta_on_first_page), fn f ->
        assert input_validations(f, :first) == [min: 1]
        assert input_validations(f, :last) == [min: 1]
        assert input_validations(f, :limit) == [min: 1]
        assert input_validations(f, :page_size) == [min: 1]

        assert input_validations(f, :after) == [maxlength: 100]
        assert input_validations(f, :before) == [maxlength: 100]
        assert input_validations(f, :offset) == [min: 0]
        assert input_validations(f, :page) == [min: 1]

        assert input_validations(f, :anything_else) == []
        ""
      end)
    end

    test "applies :max_limit if schema is set" do
      form_to_html(build(:meta_on_first_page, schema: Pet), fn f ->
        assert input_validations(f, :first) == [min: 1, max: 200]
        assert input_validations(f, :last) == [min: 1, max: 200]
        assert input_validations(f, :limit) == [min: 1, max: 200]
        assert input_validations(f, :page_size) == [min: 1, max: 200]
        ""
      end)
    end

    test "adds maxlength to all filter text input fields" do
      fields = [:float, :string, :decimal]
      filters = Enum.map(fields, &%Filter{field: &1})

      meta =
        build(:meta_on_first_page,
          flop: %Flop{filters: filters},
          schema: __MODULE__.TestSchema
        )

      form_to_html(meta, fn f ->
        inputs_for(f, :filters, fn fo ->
          assert input_validations(fo, :value) == [maxlength: 100]
          ""
        end)
      end)
    end
  end

  describe "input_value/2" do
    test "returns value from flop struct" do
      meta = build(:meta_on_first_page)

      form_to_html(meta, fn f ->
        assert input_value(f, :page_size) == meta.flop.page_size
        assert input_value(f, :page) == meta.flop.page
        ""
      end)
    end

    test "returns value from filter struct" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{filters: [%Filter{field: :age, op: :>=, value: 8}]}
        )

      form_to_html(meta, fn f ->
        inputs_for(f, :filters, fn fo ->
          assert input_value(fo, :field) == :age
          assert input_value(fo, :op) == :>=
          assert input_value(fo, :value) == 8
          ""
        end)
      end)
    end

    test "raises error for string field" do
      meta = build(:meta_on_first_page)
      msg = ~s(expected field to be an atom, got: "page_size")

      assert_raise ArgumentError, msg, fn ->
        form_to_html(meta, fn f ->
          assert input_value(f, "page_size")
          ""
        end)
      end
    end
  end
end
