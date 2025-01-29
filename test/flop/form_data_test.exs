defmodule Flop.Phoenix.FormDataTest do
  use ExUnit.Case

  import Flop.Phoenix.Factory
  import Phoenix.HTML.Form

  alias Flop.Filter
  alias MyApp.Pet
  alias Phoenix.HTML.FormData

  describe "to_form/2" do
    test "with meta struct" do
      meta = build(:meta_on_first_page, errors: [limit: [{"whatever", nil}]])
      form = FormData.to_form(meta, [])
      assert form.source == meta
      assert form.id == "flop"
      assert form.name == nil
      assert form.data == meta.flop
      assert form.hidden == [page_size: meta.flop.page_size]
      assert form.params == %{}
      assert form.errors == meta.errors
      assert form.index == nil
    end

    test "with :as" do
      meta = build(:meta_on_first_page)
      form = FormData.to_form(meta, as: :flop)
      assert form.name == "flop"
      assert form.id == "flop"
    end

    test "with :id" do
      meta = build(:meta_on_first_page)
      form = FormData.to_form(meta, id: "flip", as: :flop)
      assert form.name == "flop"
      assert form.id == "flip"
    end

    test "with hidden inputs" do
      meta = build(:meta_on_first_page)
      form = FormData.to_form(meta, [])
      assert form.hidden == [page_size: meta.flop.page_size]

      meta = build(:meta_on_first_page, flop: %Flop{limit: 15, page_size: nil})
      form = FormData.to_form(meta, [])
      assert form.hidden == [limit: 15]

      meta = build(:meta_on_first_page, flop: %Flop{first: 20})
      form = FormData.to_form(meta, [])
      assert form.hidden == [first: 20]

      meta = build(:meta_on_first_page, flop: %Flop{last: 25})
      form = FormData.to_form(meta, [])
      assert form.hidden == [last: 25]
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

      form = FormData.to_form(meta, [])
      assert form.hidden == []
    end

    test "with hidden inputs for order" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{order_by: [:name, :age], order_directions: [:desc, :asc]}
        )

      form = FormData.to_form(meta, [])

      assert form.hidden == [
               order_directions: [:desc, :asc],
               order_by: [:name, :age]
             ]
    end

    test "with additional hidden inputs" do
      meta = build(:meta_on_first_page)
      form = FormData.to_form(meta, hidden: [something: "else"])
      assert form.hidden == [page_size: 10, something: "else"]
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

      form = FormData.to_form(meta, [])
      assert [filter_form] = FormData.to_form(meta, form, :filters, [])

      assert filter_form.source == meta
      assert filter_form.id == "flop_filters_0"
      assert filter_form.name == "filters[0]"
      assert filter_form.data == filter
      assert filter_form.hidden == [op: :like, field: :name]
      assert filter_form.params == %{}
      assert filter_form.errors == []
      assert filter_form.index == 0
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

      form = FormData.to_form(meta, [])

      assert [filter_form_1, filter_form_2, filter_form_3] =
               FormData.to_form(meta, form, :filters, [])

      assert form.data == meta.flop

      assert form.params == %{
               "filters" => [
                 %{"field" => :name, "op" => :like, "value" => "George"},
                 %{"field" => "age", "op" => "<>", "value" => "8"},
                 %{"field" => :species, "value" => "dog"}
               ],
               "page" => 0
             }

      assert Keyword.get(form.errors, :page) == [
               {"must be greater than %{number}",
                [validation: :number, kind: :greater_than, number: 0]}
             ]

      assert [[], filter_errors_2, []] = Keyword.get(form.errors, :filters)
      assert [op: [{"is invalid", _}]] = filter_errors_2

      assert filter_form_1.errors == []
      assert filter_form_2.errors == filter_errors_2
      assert filter_form_3.errors == []

      assert filter_form_1.params == %{
               "field" => :name,
               "op" => :like,
               "value" => "George"
             }

      assert filter_form_2.params == %{
               "field" => "age",
               "op" => "<>",
               "value" => "8"
             }

      assert filter_form_3.params == %{
               "field" => :species,
               "value" => "dog"
             }
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

      form = FormData.to_form(meta, [])

      assert [filter_form_1, filter_form_2, filter_form_3] =
               FormData.to_form(meta, form, :filters, [])

      assert form.errors == []
      assert filter_form_1.errors == []
      assert filter_form_2.errors == []
      assert filter_form_3.errors == []
    end

    test "with :default option" do
      meta = build(:meta_on_first_page, flop: %Flop{filters: []})
      default_filter = %Filter{field: :name, op: :!=}

      form = FormData.to_form(meta, [])

      assert [filter_form] =
               FormData.to_form(meta, form, :filters, default: [default_filter])

      assert filter_form.data == default_filter
      assert filter_form.data == %Filter{field: :name, op: :!=, value: nil}
      assert filter_form.hidden == [op: :!=, field: :name]
      assert filter_form.id == "flop_filters_0"
      assert filter_form.index == 0
      assert filter_form.name == "filters[0]"
    end

    test "with :fields option" do
      meta = build(:meta_on_first_page, flop: %Flop{filters: []})
      opts = [fields: [:name, :age]]

      form = FormData.to_form(meta, [])

      assert [filter_form_1, filter_form_2] =
               FormData.to_form(meta, form, :filters, opts)

      assert filter_form_1.data == %Flop.Filter{
               field: :name,
               op: :==,
               value: nil
             }

      assert filter_form_2.data == %Flop.Filter{
               field: :age,
               op: :==,
               value: nil
             }
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

      form = FormData.to_form(meta, [])

      assert [filter_form_1, filter_form_2] =
               FormData.to_form(meta, form, :filters, opts)

      # matching should be done via name and operator; the only matching filter
      # in meta.flop is the name filter

      assert filter_form_1.data == %Flop.Filter{
               field: "name",
               op: :==,
               value: "George"
             }

      assert filter_form_2.data == %Flop.Filter{
               field: :age,
               op: :==,
               value: nil
             }
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

      form = FormData.to_form(meta, [])

      assert [filter_form_1, filter_form_2] =
               FormData.to_form(meta, form, :filters, opts)

      assert filter_form_1.params == %{
               "field" => :age,
               "op" => :>,
               "value" => 8
             }

      assert filter_form_2.params == %{"field" => :name, "value" => "Peter"}

      # none of the errors in the meta struct belong to the fields passed in the
      # options
      assert filter_form_1.errors == []
      assert filter_form_2.errors == []
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

      form = FormData.to_form(meta, [])

      assert [filter_form_1, filter_form_2] =
               FormData.to_form(meta, form, :filters, opts)

      assert filter_form_1.params == %{"field" => "age", "value" => ""}

      assert filter_form_2.params == %{
               "field" => "name",
               "value" => "",
               "op" => "ilike_and"
             }
    end

    test "with :fields and :op option" do
      meta = build(:meta_on_first_page, flop: %Flop{filters: []})
      opts = [fields: [:name, {:age, op: :>}]]

      form = FormData.to_form(meta, [])
      assert [_, filter_form_2] = FormData.to_form(meta, form, :filters, opts)
      assert filter_form_2.data == %Flop.Filter{field: :age, op: :>, value: nil}
      assert filter_form_2.hidden == [op: :>, field: :age]
    end

    test "with :fields and :default option" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{filters: [%Filter{field: :age, op: :>=, value: 10}]}
        )

      opts = [fields: [{:name, default: "George"}, {:age, op: :>=, default: 8}]]

      form = FormData.to_form(meta, [])

      assert [filter_form_1, filter_form_2] =
               FormData.to_form(meta, form, :filters, opts)

      assert filter_form_1.data == %Flop.Filter{
               field: :name,
               op: :==,
               value: "George"
             }

      assert filter_form_2.data == %Flop.Filter{field: :age, op: :>=, value: 10}
    end

    test "with filters and :id option on parent form" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :like, value: "George"}]
          }
        )

      form = FormData.to_form(meta, id: "f1ltah")
      assert [filter_form] = FormData.to_form(meta, form, :filters, [])
      assert filter_form.id == "f1ltah_filters_0"
    end

    test "with filters and :id option on filter form" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :like, value: "George"}]
          }
        )

      form = FormData.to_form(meta, [])
      assert [filter_form] = FormData.to_form(meta, form, :filters, id: "fla")
      assert filter_form.id == "fla_filters_0"
    end

    test "with filters and :as option on parent form" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :like, value: "George"}]
          }
        )

      form = FormData.to_form(meta, as: "flip")
      assert [filter_form] = FormData.to_form(meta, form, :filters, [])

      assert filter_form.id == "flip_filters_0"
      assert filter_form.name == "flip[filters][0]"
    end

    test "with filters and skip_hidden_op option" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :like, value: "George"}]
          }
        )

      opts = [skip_hidden_op: true]
      form = FormData.to_form(meta, [])
      assert [filter_form] = FormData.to_form(meta, form, :filters, opts)

      assert filter_form.hidden == [field: :name]
    end

    test "omits hidden input for default :op (:==)" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [%Filter{field: :name, op: :==, value: "George"}]
          }
        )

      form = FormData.to_form(meta, [])
      assert [filter_form] = FormData.to_form(meta, form, :filters, [])

      assert filter_form.hidden == [field: :name]
    end

    test "omits fields that are not filterable" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{
            filters: [
              %Filter{field: :age, op: :==, value: 10},
              %Filter{field: :species, op: :==, value: "dog"}
            ]
          },
          schema: Pet
        )

      opts = [fields: [:species, :age, :specialty]]
      form = FormData.to_form(meta, [])
      assert [filter_form] = FormData.to_form(meta, form, :filters, opts)
      assert filter_form.data == %Flop.Filter{field: :age, op: :==, value: 10}
    end

    @tag :capture_log
    test "omits fields that are not filterable with string params" do
      params = %{
        "page" => 0,
        "filters" => [
          %{"field" => :age, "op" => :==, "value" => 10},
          %{"field" => :species, "op" => :==, "value" => "dog"}
        ]
      }

      {:error, meta} = Flop.validate(params, for: Pet)
      opts = [fields: [:species, :age, :specialty]]
      form = FormData.to_form(meta, [])
      assert [filter_form] = FormData.to_form(meta, form, :filters, opts)

      assert filter_form.params == %{
               "field" => :age,
               "op" => :==,
               "value" => 10
             }
    end

    test "raises error with unsupported options" do
      meta = build(:meta_on_first_page)

      for opt <- [:hidden, :as, :append, :prepend] do
        msg = ":#{opt} is not supported on inputs_for with Flop.Meta."

        assert_raise ArgumentError, msg, fn ->
          form = FormData.to_form(meta, [])
          FormData.to_form(meta, form, :filters, [{opt, :some_value}])
        end
      end
    end

    test "with unknown fields" do
      meta = build(:meta_on_first_page)

      msg =
        "Only :filters is supported on " <>
          "inputs_for with Flop.Meta, got: :something."

      assert_raise ArgumentError, msg, fn ->
        form = FormData.to_form(meta, [])
        FormData.to_form(meta, form, :something, [])
      end
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
        :utc_datetime_usec,
        :compound,
        :join_default,
        :join_integer,
        :custom_date
      ],
      sortable: [],
      compound_fields: [compound: [:string, :string2]],
      join_fields: [
        join_default: [binding: :pets, field: :species],
        join_integer: [binding: :pets, field: :species, ecto_type: :integer]
      ],
      custom_fields: [
        custom_date: [
          filter: {CustomFilters, :date_filter, []},
          ecto_type: :date
        ]
      ]
    }

    schema "test_schema" do
      field(:integer, :integer)
      field(:float, :float)
      field(:boolean, :boolean)
      field(:string, :string)
      field(:string2, :string)
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
      meta = build(:meta_on_first_page)
      form = FormData.to_form(meta, [])

      assert input_validations(form, :first) == [min: 1]
      assert input_validations(form, :last) == [min: 1]
      assert input_validations(form, :limit) == [min: 1]
      assert input_validations(form, :page_size) == [min: 1]

      assert input_validations(form, :after) == [maxlength: 100]
      assert input_validations(form, :before) == [maxlength: 100]
      assert input_validations(form, :offset) == [min: 0]
      assert input_validations(form, :page) == [min: 1]

      assert input_validations(form, :anything_else) == []
    end

    test "applies :max_limit if schema is set" do
      meta = build(:meta_on_first_page, schema: Pet)
      form = FormData.to_form(meta, [])

      assert input_validations(form, :first) == [min: 1, max: 200]
      assert input_validations(form, :last) == [min: 1, max: 200]
      assert input_validations(form, :limit) == [min: 1, max: 200]
      assert input_validations(form, :page_size) == [min: 1, max: 200]
    end

    test "adds maxlength to all filter text input fields" do
      fields = [:float, :string, :decimal]
      filters = Enum.map(fields, &%Filter{field: &1})

      meta =
        build(:meta_on_first_page,
          flop: %Flop{filters: filters},
          schema: __MODULE__.TestSchema
        )

      form = FormData.to_form(meta, [])

      for filter_form <- FormData.to_form(meta, form, :filters, []) do
        assert input_validations(filter_form, :value) == [maxlength: 100]
      end
    end
  end

  describe "input_value/2" do
    test "returns value from flop struct" do
      meta = build(:meta_on_first_page)
      form = FormData.to_form(meta, [])

      assert input_value(form, :page_size) == meta.flop.page_size
      assert input_value(form, :page) == meta.flop.page
    end

    test "returns value from filter struct" do
      meta =
        build(:meta_on_first_page,
          flop: %Flop{filters: [%Filter{field: :age, op: :>=, value: 8}]}
        )

      form = FormData.to_form(meta, [])
      assert [filter_form] = FormData.to_form(meta, form, :filters, [])

      assert input_value(filter_form, :field) == :age
      assert input_value(filter_form, :op) == :>=
      assert input_value(filter_form, :value) == 8
    end

    test "raises error for string field" do
      meta = build(:meta_on_first_page)
      form = FormData.to_form(meta, [])
      msg = ~s(expected field to be an atom, got: "page_size")

      assert_raise ArgumentError, msg, fn ->
        input_value(form, "page_size")
      end
    end
  end
end
