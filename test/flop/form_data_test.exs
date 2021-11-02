defmodule Flop.Phoenix.FormDataTest do
  use ExUnit.Case

  import Phoenix.HTML
  import Phoenix.HTML.Form
  import Flop.Phoenix.Factory

  alias Flop.Filter
  alias Flop.Phoenix.Pet
  alias Phoenix.HTML.Form

  defp form_to_html(meta, opts \\ [], function) do
    meta
    |> form_for("/", opts, function)
    |> safe_to_string()
    |> Floki.parse_fragment!()
  end

  describe "form_for/3" do
    test "with meta struct" do
      meta = build(:meta_on_first_page)

      html =
        form_to_html(meta, fn f ->
          assert f.data == meta.flop
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

      html =
        form_to_html(meta, fn f ->
          assert f.hidden == [
                   order_directions: [:desc, :asc],
                   order_by: [:name, :age]
                 ]

          Flop.Phoenix.filter_hidden_inputs_for(f)
        end)

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

    test "with :params" do
      meta = build(:meta_on_first_page)

      html =
        form_to_html(meta, [params: %{"page_size" => 25}], fn f ->
          number_input(f, :page_size)
        end)

      assert [input] = Floki.find(html, "input#flop_page_size")
      assert Floki.attribute(input, "name") == ["page_size"]
      assert Floki.attribute(input, "type") == ["number"]
      assert Floki.attribute(input, "value") == ["25"]
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
            assert fo.hidden == [field: :name, op: :like]
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

    test "with filters and :default option" do
      meta = build(:meta_on_first_page, flop: %Flop{filters: []})

      html =
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, [default: [%Filter{field: :name}]], fn fo ->
            assert fo.data == %Filter{field: :name, op: :==, value: nil}
            assert fo.hidden == [field: :name, op: :==]
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
      assert Floki.attribute(input, "value") == ["=="]

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
              %Filter{field: :name, value: "George"},
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
