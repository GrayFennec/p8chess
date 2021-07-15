pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--main code
--global vars--
--current coordinates of hover
hovr = 1
hovc = 1
--current selected coordinates
selr = nil
selc = nil
--board size 
brdw = 8
brdh = 8
--winner 
--0 = no winner yet
--1 = checkmate
--2 = stalemate
winr = 0
--show promotion ui?
promui = false
--current promotion hover
promsel = nil

function _update()
	--update hover
	update_hover()
	--update selec
	update_selec()
end

--checks for check/stale mate
--for current player
function update_mates()
 canmove = false
 --iterate to find legal moves
 for r=1,brdh do
  for c=1,brdw do
   if get_pnum(gb,r,c) == turn and #legal_moves(r,c) != 0 then
    canmove = true
   	break
   end
  end
 end
 --no legal moves means mate
 if not canmove then
  --incheck -> checkmate
  if update_check(gb,turn) then
   winr = 1
  --nocheck -> stalemate
  else
   winr = 2
  end
 end 
end

--player button input
function update_hover()
 if promui then
  if btnp(0) and promsel>1 then
   promsel = promsel-1
  end
  if btnp(1) and promsel<4 then
   promsel = promsel+1
  end
 else
		if btnp(0) and hovc>1 then
			hovc = hovc-1
		end
		if btnp(1) and hovc<brdw then
			hovc = hovc+1
		end
		if btnp(2) and hovr>1 then
		hovr = hovr-1
		end
		if btnp(3) and hovr<brdh then
			hovr = hovr+1
		end
	end
end

function update_selec()
	if btnp(4) then
	 if promui then
	  if promsel == 1 then
	   p = new_knight(turn)
	  elseif promsel == 2 then
	   p = new_bishop(turn)
	  elseif promsel == 3 then
	   p = new_rook(turn)
	  elseif promsel == 4 then
	   p = new_queen(turn)
	  end
	  gb[hovr][hovc] = p
	  promui = false
	  change_turn()
	 elseif selr == nil and get_pnum(gb, hovr, hovc) == turn then
	  selr = hovr
	  selc = hovc
	  return
	 elseif selr != nil then
	  try_move(selr, selc, hovr, hovc)
	 end
	elseif not btnp(5) then
	 return
	end
	selr = nil
	selc = nil
end

--moves piece obj to destination
--if it is a valid move
--begr, begc: the beginning coordinates 
--desr, desc: the destination coordinates
function try_move(begr, begc, desr, desc)
 moves = legal_moves(begr,begc)
 --check if coords are legal move
	for move in all(moves) do
	 if move[1] == desr and move[2] == desc then
	  --update castling if king is moved
	  if is_king(gb, begr, begc) then
	   rookloc[turn] = {nil,nil}
		 end
		 --update castling is rook moved
		 if is_rook(begr, begc) then
		  for dir,rc in pairs(rookloc[turn]) do
		   if begc == rc and begr == -7*turn+15 then
		    rookloc[turn][dir] = nil
		   end 
		  end
		 end
		 --special moves
		 --check if mvoe is enpassant
		 if move.enpassant then
		  --remove enemy pawn
		  gb[begr][desc] = nil
		 end
		 --check if move is castle
	  if move.castle then
	   --check if kingside or queenside
	   if move[2] < begc then
 				rc = 4
	   else
	    rc = 6
	   end
	   --save king
	   king = gb[begr][begc]
	   gb[begr][begc] = nil
	   --move rook
	   move_piece(gb, desr, desc, desr, rc)
	   --place king
	   gb[desr][2*rc-5] = king
	  else
		  --move the piece normally
		  move_piece(gb, begr, begc, desr, desc)
	  end
	  --check if move was double step
	  if move.double then
	   eploc = {desr-2*turn+3,desc,enpassant = true}
	  else
	   eploc = nil
	  end
	  --check if move was pawn to last rank
	  if move.promote then
	   promui = true
	   promsel = 1
	   --gb[desr][desc] = new_queen(turn)
	  else
		  --increment turn
		  change_turn()
	  end
	 end
	end
end

function change_turn()
 turn = turn % 2 + 1
  --check for mate
 update_mates()
end

--moves a piece on a board
--begr, begc: the beginning coordinates 
--desr, desc: the destination coordinates
--b: the board to make the move on
function move_piece(b, begr, begc, desr, desc)
 b[desr][desc] = gb[begr][begc]
 b[begr][begc] = nil
end

--updates value of incheck to show if current player is now in check
--b: the board to check for checks
--p: the player to check if in check
function update_check(b,p)
 --go through every piece
 for r=1,brdh do
  for c=1,brdw do
   if is_piece(b,r,c) and b[r][c].pnum != p then
   	moves = b[r][c].movl(b,r,c)
   	--check all moves
  		for move in all(moves) do
   		if is_king(b,move[1],move[2]) then
   	 	return true
   	 end
   	end
   end
  end
 end
 return false
end

--gets all legal moves of piece
--r, c: the coordinates of the piece
function legal_moves(r,c)
			local moves = gb[r][c].movl(gb,r,c)
			for move in all(moves) do
			 --test move
			 make_tb()
			 move_piece(tb, r, c, move[1], move[2])
			 if update_check(tb, turn) then
			  del(moves, move)
			 end
			end
			--castling logic
			--if piece is king
			if is_king(gb,r,c) then
			 --check for castleable rooks
				--rc: rook column
				--dir: direction 1 = queenside, 2 = kingside
				for dir,rc in pairs(rookloc[turn]) do
					d = 2*dir
					rd = 2+d
					kd = rd-3+d
					--make testboard
					make_tb()
					--remove king and rook
					tb[r][c] = nil
					tb[r][rc] = nil
					--test if paths are clear
					if path_clear(r,c,kd) and path_clear(r,rc,rd) then
						--test if every square is safe
						local safe = true
						for path=min(kd,c),max(kd,c) do
						 tb[r][path] = gb[r][c]
						 safe = safe and not update_check(tb,turn)
						 tb[r][path] = nil
						end
						--if path is safe add the castle
						if safe then
						 add(moves, {r,rc,castle = true})
						end
					end 
				end
			end
			--en passant logic
			if gb[r][c].sprnum == 0 and eploc != nil and abs(eploc[2]-c) == 1 and eploc[1]-2*turn+3 == r then
			 --test en passant
			 make_tb()
			 move_piece(tb,r,c,eploc[1],eploc[2])
			 tb[r][eploc[2]] = nil
			 if not update_check(tb, turn) then
			  add(moves, eploc)
			 end
			end
			return moves
end

--makes test board by cloning current game board
function make_tb()
	for r=1,brdh do
		for c=1,brdw do
		 tb[r][c] = gb[r][c]
		end
	end
end


-->8
--piece constructors

--abstract create new piece
--p=player
function new_piece(p)
	obj = {
		pnum = p
	}
 return obj
end

--creates a new pawn
function new_pawn(p)
	pawn = new_piece(p)
	pawn.sprnum = 0
	pawn.movl = function(b,r,c)
	 local moves = {}
	 local f = p == 1 and -1 or 1
	 local prom = r+f == 1 or r+f == brdh 
	 --captures
	 --todo: make math better
	 if get_pnum(b,r+f,c-1) ^^ p == 3 then
	  add(moves,{r+f,c-1,promote = prom})
	 end
	 if get_pnum(b,r+f,c+1) ^^ p == 3 then
	  add(moves,{r+f,c+1,promote = prom})
	 end
	 --one row foward move
	 if get_pnum(b,r+f,c) == 0 then
	  add(moves,{r+f,c,promote = prom})
	  --two row foward move
	  if r-f == 1 or r-f == brdh then
	   f*=2
	   if get_pnum(b,r+f,c) == 0 then
	  	 add(moves,{r+f,c,double = true,promote = prom})
	   end
	  end
	 end
		return moves
	end
	return pawn
end

--creates a new knight
function new_knight(p)
	knight = new_piece(p)
	knight.sprnum = 2
	knight.movl = function(b,r,c)
		local moves = {}
	 --calculate values one and two away
		tup = r-2
		oup = r-1
		tdo = r+2
		odo = r+1
		tle = c-2
		ole = c-1
		tri = c+2
		ori = c+1
		--create possible moves
		local possi = {{tup, ole},{tup,ori},{oup,tle},{oup,tri},{odo,tle},{odo,tri},{tdo,ole},{tdo,ori}}
		for move in all(possi) do
		 local dnum = get_pnum(b,move[1], move[2])
		 if dnum != 3 and dnum != p then
		  add(moves, move)
		 end
		end
		return moves
	end
	return knight
end

--creates a new bishop
function new_bishop(p)
	bishop = new_piece(p)
	bishop.sprnum = 4
	bishop.movl = function(b,r,c)
	 local moves = {}
	 --table of diagonals
	 local direc = {{1, 1, true},{1, -1, true},{-1, -1, true},{-1, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  --add moves along diagonals
	  for d in all(direc) do
	   if d[3] then
	    local dnum = get_pnum(b,r+i*d[1], c+i*d[2])
	    if dnum > 0 then
	     d[3] = false
	    end
	    if dnum != 3 and dnum != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	return bishop
end

--creates a new rook
function new_rook(p)
	rook = new_piece(p)
	rook.sprnum = 6
	rook.movl = function(b,r,c)
	 local moves = {}
	 --table of straights
	 local direc = {{1, 0, true},{0, -1, true},{-1, 0, true},{0, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  --add moves along straights
	  for d in all(direc) do
	   if d[3] then
	    local dnum = get_pnum(b,r+i*d[1], c+i*d[2])
	    if dnum > 0 then
	     d[3] = false
	    end
	    if dnum != 3 and dnum != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	return rook
end

--creates a new queen
function new_queen(p)
	queen = new_piece(p)
	queen.sprnum = 8
	queen.movl = function(b,r,c)
	 local moves = {}
	 --table of 8 directions
	 local direc = {{1, 1, true},{1, 0, true},{1, -1, true},{0, -1, true},{-1, -1, true},{-1, 0, true},{-1, 1, true},{0, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  --add moves along each direction
	  for d in all(direc) do
	   if d[3] then
	    local dnum = get_pnum(b,r+i*d[1], c+i*d[2])
	    if dnum > 0 then
	     d[3] = false
	    end
	    if dnum != 3 and dnum != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	return queen
end

--creates a new king
function new_king(p)
	king = new_piece(p)
	king.sprnum = 10
	king.movl = function(b,r,c)
	 local moves = {}
	 --calculate values one away
		oup = r-1
		odo = r+1
		ole = c-1
		ori = c+1
		local possi = {{oup, ole},{oup,ori},{r,ole},{r,ori},{odo,ole},{odo,ori},{odo,c},{oup,c}}
		for m in all(possi) do
			local dnum = get_pnum(b, m[1], m[2]) 
		 if dnum != 3 and dnum != p then
		  add(moves, m)
		 end
		end
		return moves
	end
	return king
end
-->8
--draw code
function _draw()
	draw_board()
	--draw moves of piece hovered over
	if selr != nil then
	 draw_selec()
	 draw_moves(selr,selc)
	end
	draw_every()
	if promui then
	 draw_promo()
	else
	 draw_hover()
	end
	--cheap check/stalemate print
 if winr > 0 then
	 draw_winr()
	end
end

--draws the board
function draw_board()
	pal(1, 15)
	pal(2, 4)
	for r=1,brdh do
		for c=1,brdw do
			--draw background square
			rectfill(c*16-16, r*16-16, c*16-1, r*16-1, (r+c)%2+1)
		end
	end
	pal()
end

--draws every piece
function draw_every()
	for r=1,8 do
		for c=1,8 do
			draw_piece(r,c)
		end
	end
end

--draws any location
function draw_piece(r,c)
 palt(14)
	if gb[r][c] != nil then
	 obj = gb[r][c]
	else
	 return
	end
	if(obj.pnum == 1) then
		pal(0, 7)
		pal(7, 0)
	end
	spr(obj.sprnum, c*16-16, r*16-16, 2, 2)
	pal()
end

--draws a piece's possible moves
function draw_moves(r,c)
 palt(14)
 if gb[r][c] != nil then
		moves = legal_moves(r,c)
		foreach(moves, draw_amove)
	end
end

--draws a single move
function draw_amove(move)
	r = move[1]
	c = move[2]
	--move to empty square
	if gb[r][c] == nil then
		spr(12, c*16-16, r*16-16, 2, 2)
 --capture
 else
  spr(14, c*16-16, r*16-16, 2, 2)
 	--rectfill(c*16-12, r*16-12, c*16-5, r*16-5, 11) 
 end
end

function draw_hover()
	rect(hovc*16-16, hovr*16-16, hovc*16-1, hovr*16-1, 12)
end

function draw_selec()
 rectfill(selc*16-16, selr*16-16, selc*16-1, selr*16-1, 11)
end

function draw_winr()
 if turn == 1 then
 	pal(0,7)
 	pal(7,0)
 end
 rectfill(0,0,127,127,0)
 if winr == 2 then
  spr(96,34,32,8,2) 
 else
  spr(64,34,32,8,2) 
 end
 spr(72,40,48,6,2)
end

--draw promotion ui
function draw_promo()
 if turn == 2 then
  pal(0,7)
  pal(7,0)
 end
 rectfill(32,56,95,71,7)
 rect(32,56,95,71,0)
 palt(14)
 spr(2,32,56,8,2)
 rect(16+16*promsel,56,31+16*promsel,71,12)
end
-->8
--init code
function _init()
	--init board to 8x8
	init_board(brdw,brdh)
 import_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
 --import_fen(stat(4))
end

--initialize rookloc by finding
--outermost rooks on home rows
function init_castl()
 --find each players outermost rook(s)
 rookloc = {{nil,nil},{nil,nil}}
 kc = nil
 for p,r in pairs({8,1}) do
 	for c=1,brdw do
			if is_king(gb,r,c) then
			 kc = c
			end
	 end
	 if kc != nil then
		 for c=kc,brdw do
		 	if is_rook(r,c) then
		   rookloc[p][2] = c
		 	end
		 end
		 for c=kc,1,-1 do
		 	if is_rook(r,c) then
		   rookloc[p][1] = c
		 	end
		 end
		end
 end
end

--initalizes empty nxm board
function init_board(n,m)
 gb = {}
 tb = {}
	for r=1,n do
		gb[r] = {}
		tb[r] = {}
		for c=1,m do
			gb[r][c] = nil
			tb[r][c] = nil
		end
	end
end

function import_fen(fen)
 --split fen into secitons
 data = split(fen," ")
 --create board
 for r,cdata in pairs(split(data[1],"/")) do
  c = 1
  while cdata != "" do
	  n = sub(cdata,1,1)
	  if tonum(n) then
	   c += n
	  else
    v = c2v[n]
    p = v > 6 and 2 or 1
    v %= 6
    if v == 1 then
     piece = new_pawn(p)
    elseif v == 2 then
     piece = new_knight(p)
    elseif v == 3 then
     piece = new_bishop(p)
    elseif v == 4 then
     piece = new_rook(p)
    elseif v == 5 then 
     piece = new_queen(p)
    elseif v == 0 then
     piece = new_king(p)
    end
    gb[r][c] = piece
	   c += 1
	  end
	  cdata = sub(cdata,2) 
	 end
	end
	--figure out turn
	turn = data[2] == "w" and 1 or 2
 --castling ability
 --create initial vars
 init_castl()
 i = 1
 n = sub(data[3],i,i)
 for k,v in pairs({"\75","\81","k","q"}) do
	 if n == v then
	  i += 1
	 	n = sub(data[3],i,i)
	 else
	  rookloc[k\3+1][k%2+1] = nil
	 end
	end
	--enpassant
	if data[4] == "-" then
	 eploc = nil
	else
	 eploc = {c2c[sub(data[4],1,1)],tonum(sub(data[4],2))}
	end
end

--fen chars to piece values
vchars="PNBRQKpnbrqk"
--fen chars to column values
cchars="abcdefgh"
c2v={}
c2c={}
for i = 1,12 do
 c2v[sub(vchars,i,i)]=i
 c2c[sub(cchars,i,i)]=i
end
-->8
--helper functions
--castling helper function
--checks if path on test board is clear
--r: row of the path
--c1: one end of path
--c2: other end of path
function path_clear(r, c1, c2)
	for c=min(c1,c2),max(c1,c2) do
	 if is_piece(tb,r,c) then
	 	return false
	 end
	end
	return true
end

--castling helper function
--checks if coordinate on gb is rook
--r,c: coordinate to check
function is_rook(r,c)
 return is_piece(gb,r,c) and gb[r][c].sprnum == 6
end

--check and castling helper function
--checks if coordinate on board is king
--r,c: coordinate to check
--b: the board to check
function is_king(b,r,c)
 return is_piece(b,r,c) and b[r][c].sprnum == 10 
end

--gets pnum of square
--if empty 0
--if invalid 3
--r,c: coordinate of square
--b: board being checked
function get_pnum(b,r,c)
	if val_coord(r,c) then
	 if is_piece(b,r,c) then
	 	return b[r][c].pnum
	 else
	 	return 0
	 end
	else
	 return 3
	end
end

--tests is square is not empty
--r,c: coordinate to check
--b: board to check
function is_piece(b,r,c)
 return b[r][c] != nil
end

--checks if a coordinate valid
--r,c: coordinate to check
function val_coord(r,c)
	return r > 0 and c > 0 and r <= brdh and c <= brdw
end
__gfx__
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbbbeeeeeeeebbbb
eeeeee7777eeeeeeeeeee7ee7eeeeeeeeeeeeee77eeeeeeeeee77e7ee7e77eeeee7ee7eeee7ee7eeeeeeeee77eeeeeeeeeeeeeeeeeeeeeeebbbeeeeeeeeeebbb
eeeee700007eeeeeeeee707707eeeeeeeeeeee7007eeeeeeeee7070770707eeee707707ee707707eeeeeee7777eeeeeeeeeeeeeeeeeeeeeebbeeeeeeeeeeeebb
eeee70000007eeeeeeee7000007eeeeeeeeee700007eeeeeeee7000000007eeeee707707707707eeeeeeeee77eeeeeeeeeeeeeeeeeeeeeeebeeeeeeeeeeeeeeb
eeee70000007eeeeeee70000007eeeeeeeeee700007eeeeeeee7000000007eeeee707707707707eeeee777e77e777eeeeeeeeebbbbeeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeee707000007eeeeeeee70077007eeeeeeee70777707eeeeee700707707007eeee700077770007eeeeeeebbbbbbeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeee7000000007eeeeeeee70077007eeeeeeee70000007eeeeeee7070000707eeee70000777700007eeeeebbbbbbbbeeeeeeeeeeeeeeeeeeee
eeeee700007eeeeeee7000700007eeeeeeeee700007eeeeeeeeee700007eeeeeeee7000000007eeee70000077000007eeeeebbbbbbbbeeeeeeeeeeeeeeeeeeee
eeeeee7007eeeeeeee70070000007eeeeeeeee7007eeeeeeeeeee700007eeeeeeee7000000007eeee70000077000007eeeeebbbbbbbbeeeeeeeeeeeeeeeeeeee
eeeee700007eeeeeeee7770000007eeeeeeee700007eeeeeeeeee700007eeeeeeeee70000007eeeeee700007700007eeeeeebbbbbbbbeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeeeee70000007eeeeeee70077007eeeeeeee70000007eeeeeeee70777707eeeeeee7777777777eeeeeeeebbbbbbeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeeee700000007eeeeeee77000077eeeeeeee70777707eeeeeee7000000007eeeeee7000770007eeeeeeeeebbbbeeeeeeeeeeeeeeeeeeeeee
eee7000000007eeeeee70000000007eeeee7000000007eeeeee7000000007eeeeee7077777707eeeeee7700770077eeeeeeeeeeeeeeeeeeebeeeeeeeeeeeeeeb
eee7000000007eeeeee70000000007eeee700000000007eeeee7000000007eeeeee7000000007eeeeeee70077007eeeeeeeeeeeeeeeeeeeebbeeeeeeeeeeeebb
eee7777777777eeeeee77777777777eeee777777777777eeeee7777777777eeeeee7777777777eeeeeee77777777eeeeeeeeeeeeeeeeeeeebbbeeeeeeeeeebbb
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbbbeeeeeeeebbbb
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
000077777700077000007700077777777700000077777700077000007700000000770000077000000777000007777777777000777777777000000000eeeeeeee
0007777777d0077d000077d00777777777d00007777777d0077d000777d000000d7770007770000077777000d777777777700d777777777000000000eeeeeeee
00777dddddd0077d000077d0077dddddddd000777dddddd0077d00777dd000000d7777077770000d77d77000ddddd77ddd000d77dddddd0000000000eeeeeeee
0777dd000000077d000077d0077d000000000777d0000000077d0777dd0000000d7777777770000770dd77000000d77000000d770000000000000000eeeeeeee
077dd0000000077d000077d0077d00000000077dd0000000077d777dd00000000d77d777d77000d7700d77000000d77000000d770000000000000000eeeeeeee
077d000000000777777777d0077777700000077d00000000077777dd000000000d77dd70d77000d7700d77000000d77000000d777777000000000000eeeeeeee
077d000000000777777777d00777777d0000077d00000000077777d0000000000d770d00d77000d7700d77000000d77000000d777777000000000000eeeeeeee
077d00000000077ddddd77d0077ddddd0000077d0000000007777777000000000d770000d7700077777777700000d77000000d77ddd0000000000000eeeeeeee
077d00000000077d000077d0077d00000000077d00000000077ddd77700000000d770000d7700d77777777700000d77000000d770000000000000000eeeeeeee
077700000000077d000077d0077d00000000077700000000077d00077d0000000d770000d7700d77ddddd7700000d77000000d770000000000000000eeeeeeee
007770000000077d000077d0077d00000000007770000000077d0000770000000d770000d7700d770000d7700000d77000000d770000000000000000eeeeeeee
000777777700077d000077d0077777777700000777777700077d000077d000000d770000d7700d770000d7700000d77000000d777777777000000000eeeeeeee
0000777777d0077d000077d00777777777d00000777777d0077d000077d000000d770000d7700d770000d7700000d77000000d777777777000000000eeeeeeee
00000dddddd000dd00000dd000ddddddddd000000dddddd000dd00000dd000000dd00000dd000dd00000dd000000ddd000000ddddddddd0000000000eeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
000777770000077777777770000077700000077000000000077777777700000000000000000000000000000000000000000000000000000000000000eeeeeeee
00777777700007777777777d000777770000077d000000000777777777d0000000000000000000000000000000000000000000000000000000000000eeeeeeee
0777ddd7770000ddd77ddddd00077d77d000077d00000000077dddddddd0000000000000000000000000000000000000000000000000000000000000eeeeeeee
077dd00077d00000077d00000077dd077000077d00000000077d00000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
077700000dd00000077d00000077d0077d00077d00000000077d00000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
0777770000000000077d00000077d0077d00077d00000000077777700000000000000000000000000000000000000000000000000000000000000000eeeeeeee
0077777770000000077d00000077d0077d00077d000000000777777d0000000000000000000000000000000000000000000000000000000000000000eeeeeeee
000dd77777000000077d0000077777777700077d00000000077ddddd0000000000000000000000000000000000000000000000000000000000000000eeeeeeee
000000d777d00000077d00000777777777d0077d00000000077d00000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
0770000077d00000077d0000077ddddd77d0077d00000000077d00000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
0777000777d00000077d0000077d000077d0077d00000000077d00000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
007777777dd00000077d0000077d000077d0077777777700077777777700000000000000000000000000000000000000000000000000000000000000eeeeeeee
00077777dd000000077d0000077d000077d00777777777d00777777777d0000000000000000000000000000000000000000000000000000000000000eeeeeeee
0000ddddd000000000dd000000dd00000dd000ddddddddd000ddddddddd0000000000000000000000000000000000000000000000000000000000000eeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001015000000100500000010050000001005000000131500000010050000001005000000100500000017050000001305000000100500000013050000001015000000100500000010050000001005000000
__music__
00 01424344
00 01024344

