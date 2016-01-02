require 'rails_helper'
RSpec.describe GamesController, type: :controller do
  describe "GET new" do
    context "with logged in user" do
      login_user
      it "creates new game" do
        get :new
        expect(assigns(:game)).to be_a_new(Game)
      end
      it "renders the new template" do
        get :new
        expect(response).to render_template("new")
      end
    end
    context "without being logged in" do
      it "redirects to sign in page" do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET show" do
    # TO-DO: replicate tests for both logged in and not-logged in user
    render_views
    let(:game) { create(:game) }
    context 'with valid params' do
      it "assigns the requested game to @game" do
        get :show, id: game
        expect(assigns(:game)).to eq(game)
      end
      it "has a 200 status code for an existing game" do
        get :show, id: game.id
        (expect(response.status).to eq(200))
      end
      it "renders the show view" do
        get :show, id: game.id
        expect(response).to render_template("show")
      end
    end
    context 'with invalid params' do
      it "has a 404 status code for an non-existant game" do
        get :show, id: "LOL"
        (expect(response.status).to eq(404))
      end
    end
  end

  describe 'POST #create' do
    context 'with logged in user' do
      login_user
      context 'with valid params' do
        context 'with white player creating the game' do
          it 'redirects to show page' do
            post :create, game: { game_name: "Test White",
                                  creator_plays_as_black: "0" }
            expect(response).to redirect_to(Game.last)
          end
          it 'sets all white pieces to be owned by white player' do
            post :create, game: { game_name: "Test White", creator_plays_as_black: "0" }
            expect(Game.last.pieces.where(user_id: subject.current_user.id)
              .count).to eq 16
            expect(Game.last.pieces.where(user_id: nil)
              .count).to eq 16
          end
          it "sets the current user's turn if they are the white player" do
            post :create, game: { game_name: "Test White", creator_plays_as_black: "0" }
            expect(Game.last.user_turn).to eq(subject.current_user.id)
          end
        end
        context 'with black player creating the game' do
          it 'redirects to show page' do
            post :create, game: { game_name: "Test Black",
                                  creator_plays_as_black: "1" }
            expect(response).to redirect_to(Game.last)
          end
          it 'sets all black pieces to be owned by black player' do
            post :create, game: { game_name: "Test Black",
                                  creator_plays_as_black: "1" }
            expect(Game.last.pieces.where(user_id: subject.current_user.id)
              .count).to eq 16
            expect(Game.last.pieces.where(user_id: nil)
              .count).to eq 16
          end
          it "does not set the user's turn if they are black player" do
            post :create, game: { game_name: "Test Black",
                                  creator_plays_as_black: "1" }
            expect(Game.last.user_turn).to be_nil
          end
        end
      end
      context 'with invalid params' do
        it 're-renders #new form with bad game name' do
          post :create, game: { game_name: "" }
          expect(response).to render_template(:new)
        end
        it 'raises error with bad user turn id value' do
          expect{post :create, game: { game_name: "Test Black",
                                creator_plays_as_black: "1", user_turn: (User.count+1) }}
                                .to raise_error(ActiveRecord::InvalidForeignKey)
        end
      end
    end
    context 'without being logged in' do
      it 'redirects to sign-in page' do
        post :create, game: attributes_for(:game)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with logged in user' do
      login_user
      context 'with white player joining game' do
        before :each do
          @game_to_update = build(:game)
          @game_to_update.assign_attributes(user_turn: subject.current_user.id, white_user_id: nil)
          @game_to_update.save!
        end
        it 'redirects to show page' do
          put :update, id: @game_to_update.id, game: { white_user_id: subject.current_user.id }
          expect(response).to redirect_to(@game_to_update)
        end
        it 'sets all white pieces to be owned by white player' do
          expect(@game_to_update.pieces.where(user_id: subject.current_user.id)
            .count).to eq 0
          put :update, id: @game_to_update.id, game: { white_user_id: subject.current_user.id }
          expect(@game_to_update.pieces.where(user_id: subject.current_user.id)
              .count).to eq 16
        end
        it "sets the current user's turn" do
          @game_to_update.assign_attributes(user_turn: nil)
          @game_to_update.save(validate: false) #don't validate, it won't pass
          expect(@game_to_update.user_turn).to be_nil
          put :update, id: @game_to_update.id, game: { white_user_id: subject.current_user.id }
          expect(@game_to_update.user_turn).to eq @game_to_update.white_user_id
        end
      end
      context 'with black player joining game' do
        before :each do
          @game_to_update = build(:game)
          @game_to_update.assign_attributes(user_turn: @game_to_update.white_user_id, black_user_id: nil)
          @game_to_update.save!
        end
        it 'redirects to show page' do
          put :update, id: @game_to_update.id, game: {
            black_user_id: subject.current_user.id }
            expect(response).to redirect_to(@game_to_update)
          end
        it 'sets all black pieces to be owned by black player' do
          expect(@game_to_update.pieces.where(user_id: subject.current_user.id)
            .count).to eq 0
          put :update, id: @game_to_update.id, game: {
            black_user_id: subject.current_user.id }
            expect(@game_to_update.pieces.where(user_id: subject.current_user.id)
              .count).to eq 16
        end
        it "does not set the current user's turn" do
          put :update, id: @game_to_update.id, game: {
            black_user_id: subject.current_user.id }
            expect(@game_to_update.user_turn).to eq @game_to_update.white_user_id
        end
      end
      it 'won\'t let player join full game' do
        game = create(:game)
        put :update, id: game.id, game: {
          white_user_id: subject.current_user.id }
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to be_present
          expect(flash[:alert]).to eq('Game is full!')
      end
    end
    context 'without being logged in' do
      it 'redirects to sign-in page' do
        game_to_update = create(:game)
        put :update, id: game_to_update.id, game: attributes_for(:game)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH #move' do
    context 'with logged in user' do
      login_user
      let(:black_player) { create(:user) }
      let(:game_to_update) do
        Game.create(game_name: "Test",
                    black_user_id: black_player.id)
        context 'with an AJAX request' do
          it 'redirects to pieces controller' do
            xhr :put, :move, id: game_to_update.id, piece_id: 1, x: 3, y: 3
            expect(response).to redirect_to(piece_path(piece_id))
          end
        end
        context 'with an HTML request' do
          it 'redirects to game page' do
            put :move, id: game_to_update.id, piece_id: 1, x: 3, y: 3
            expect(response).to redirect_to(game_to_update)
          end
        end
      end
    end
    context 'without being logged in' do
      context 'with an AJAX request' do
        it 'redirects to sign-in page' do
          game_to_update = create(:game)
          xhr :put, :move, id: game_to_update.id, piece_id: 1, x: 3, y: 3
          expect(response).to redirect_to(new_user_session_path)
        end
      end
      context 'with an HTML request' do
        it 'redirects to sign-in page' do
          game_to_update = create(:game)
          put :move, id: game_to_update.id, piece_id: 1, x: 3, y: 3
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  describe 'PUT #forfeit' do
    it "will declare Black player as the winner" do
      current_game = FactoryGirl.build(:game)
      current_game.assign_attributes(user_turn: current_game.white_user_id)
      current_game.save!
      black_user = current_game.black_user
      white_user = current_game.white_user
      sign_in white_user
      expect(current_game.forfeit).to be false
      put :forfeit, id: current_game
      current_game.reload
      expect(current_game.game_winner).to eq(current_game.black_user.id)
      expect(current_game.forfeit).to be true
      black_user.reload
      white_user.reload
      expect(black_user.user_wins).to eq 1
      expect(white_user.user_losses).to eq 1
    end
    it "will declare White player as the winner" do
      current_game = FactoryGirl.build(:game)
      current_game.assign_attributes(user_turn: current_game.black_user_id)
      current_game.save!
      black_user = current_game.black_user
      white_user = current_game.white_user
      sign_in black_user
      expect(current_game.forfeit).to be false
      put :forfeit, id: current_game
      current_game.reload
      expect(current_game.game_winner).to eq(current_game.white_user.id)
      expect(current_game.forfeit).to be true
      black_user.reload
      white_user.reload
      expect(white_user.user_wins).to eq 1
      expect(black_user.user_losses).to eq 1
    end
  end
  describe 'Draw' do
    context 'white player' do
      it "will request draw" do
        current_game = FactoryGirl.build(:game)
        current_game.assign_attributes(user_turn: current_game.white_user_id)
        current_game.save!
        white_user = current_game.white_user
        sign_in white_user
        put :request_draw, id: current_game
        current_game.reload
        expect(current_game.draw_request).to eq(current_game.white_user.id)
      end
      it "will be accepted" do
        current_game = FactoryGirl.build(:game)
        current_game.assign_attributes(user_turn: current_game.black_user_id, draw_request: current_game.white_user)
        current_game.save!
        black_user = current_game.black_user
        white_user = current_game.white_user
        sign_in black_user
        put :accept_draw, id: current_game
        current_game.reload
        expect(current_game.draw).to eq(true)
        black_user.reload
        white_user.reload
        expect(black_user.user_draws).to eq 1
        expect(white_user.user_draws).to eq 1
      end
      it "will be declined" do
        current_game = FactoryGirl.build(:game)
        current_game.assign_attributes(user_turn: current_game.black_user_id, draw_request: current_game.white_user)
        current_game.save!
        black_user = current_game.black_user
        sign_in black_user
        put :reject_draw, id: current_game
        current_game.reload
        expect(current_game.draw).to eq(false)
        expect(current_game.draw_request).to eq(nil)
      end
    end
    context 'black player' do
      it "will request draw" do
        current_game = FactoryGirl.build(:game)
        current_game.assign_attributes(user_turn: current_game.white_user_id)
        current_game.save!
        black_user = current_game.black_user
        sign_in black_user
        put :request_draw, id: current_game
        current_game.reload
        expect(current_game.draw_request).to eq(current_game.black_user.id)
      end
      it "will be accepted" do
        current_game = FactoryGirl.build(:game)
        current_game.assign_attributes(user_turn: current_game.black_user_id, draw_request: current_game.black_user)
        current_game.save!
        white_user = current_game.white_user
        black_user = current_game.black_user
        sign_in white_user
        put :accept_draw, id: current_game
        current_game.reload
        expect(current_game.draw).to eq(true)
        black_user.reload
        white_user.reload
        expect(black_user.user_draws).to eq 1
        expect(white_user.user_draws).to eq 1
      end
      it "will be declined" do
        current_game = FactoryGirl.build(:game)
        current_game.assign_attributes(user_turn: current_game.black_user_id, draw_request: current_game.black_user)
        current_game.save!
        white_user = current_game.white_user
        sign_in white_user
        put :reject_draw, id: current_game
        current_game.reload
        expect(current_game.draw).to eq(false)
        expect(current_game.draw_request).to eq(nil)
      end
    end
  end
end
