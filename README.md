Fall Gambit
===========
This is a chess app built in Ruby on Rails by the Fall Gambit team for The Firehose Project.
--------------------------------------------------------------------------------------------

The team is composed of the following members:

* [Jeff Gerlach](https://github.com/jeffgerlach)
* [Sharon](https://github.com/acodeinprogress)
* [amarkpark](https://github.com/amarkpark)
* [Nicola Guidi](https://github.com/nicolaguidi)

Fall Gambit is led by [Carleton DiLeo](https://github.com/cbdileo)

Visit Fall Gambit on Heroku at [fall-gambit.herokuapp.com](http://fall-gambit.herokuapp.com)

***

Fall Gambit uses RuboCop to keep the code nice and tidy.
To see it in action just run `rubocop` from the command line and see if you
committed some offense.
You can configure the `.rubocop.yml` file as you prefer.
To know more go to the [RuboCop GitHub page](https://github.com/bbatsov/rubocop)
and take a look at [The Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide)

Additional resources:
* [Getting Started](http://joanswork.com/rubocop-rails-getting-started/)
* [Fixing Rubocop errors](http://jasonnoble.org/2014/03/fixing-rubocop-errors.html)
* [Integrate Rubocop in your Workflow](https://intercityup.com/blog/integrate-rubocop-in-your-workflow.html)

***

In this section we should place conventions for USE of STI subclasses so that multiple coders will invoke method calls using the same syntax and avoid having to back out the STI.

Invoking new instances of Pieces should call the subclass-of-Piece Model to instantiate. Ex: if you want a new rook call Rook.create rather than calling Piece.create and specifying the Rook piece_type as an argument. (Please note that at the time of this writing the Game.rb populates the board by instantiating all the pieces with pre-STI calls and I have not yet decided if it is worth the time to rewrite it. ~AMP)

Delegates allow Game and User classes to reference specific pieces by piece_type to call either subclass or directly call class methods on the pieces.

Proper calling of Piece.rb Model helper method "range_occupied?(x1, x2, y1, y2)": Please be sure that any calls to this method are for values of x and y where x1 < x2 and y1 < y2. Else the query will not function correctly. You can hold either coordinate constant by inserting the same value for 1st and 2nd variable.

20151206: New Piece.rb helper method "find_piece(x, y)" should be usable by child models, but must be explicitly added to child model test specs. See knight_spec.rb as example.

