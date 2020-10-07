pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
--current coordinates of hover
hovr = 1
hovc = 1
--current piece hovered over
hovp = -1
--current tick 0 to 15
t = 0
--whoevers turn it is
turn = 0
--list of all game pieces
pl = {}
--game board
gb = {}
--board size
brdw = 8
brdh = 8

function _init()
	--init board to 8x8
	init_board(brdw,brdh)
	new_knight(7,7,1)
	new_king(4,5,1)
	new_pawn(7,6,1)
	new_pawn(2,5,2)
	new_bishop(1,1,2)
	new_rook(3,3,1)
	new_queen(6,3,1)
end

--initalizes empty nxm board
function init_board(n,m)
	for r=1,n do
		gb[r] = {}
		for c=1,m do
			gb[r][c] = -1
		end
	end
end

--abstract create new piece
--r=row c=col p=player
function new_piece(r,c,p)
	obj = {
		row = r,
		col = c,
		pnum = p
	}
 return obj
end

--adds piece to piece list
function add_piece(obj,r,c)
	pl[#pl+1] = obj
	--add pointer on game board
	gb[r][c] = #pl	
end

function val_cord(r,c)
	return r > 0 and c > 0 and r <= brdh and c <= brdw
end

--gets pnum of square
--it square empty, pnum is 0
function get_pnum(r,c)
	if val_cord(r,c) and gb[r][c] != -1 then
	 return pl[gb[r][c]].pnum
	else
	 return 0
	end
end

--creates a new pawn
function new_pawn(r,c,p)
	pawn = new_piece(r,c,p)
	pawn.sprnum = 0
	pawn.legmov = function(this)
	 local moves = {}
	 --calculate one row foward
	 local f = p == 1 and -1 or 1
	 if get_pnum(r+f,c) == 0 then
	  add(moves,{r+f,c})
	  if r-f == 1 or r-f == brdh then
	   f*=2
	   if get_pnum(r+f,c) == 0 then
	  	 add(moves,{r+f,c})
	   end
	  end
	 end
		return moves
	end
	add_piece(pawn,r,c)
end

--creates a new knight
function new_knight(r,c,p)
	knight = new_piece(r,c,p)
	knight.sprnum = 2
	knight.legmov = function(this)
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
		for m in all(possi) do
		 if get_pnum(m[1], m[2]) != p then
		  add(moves, m)
		 end
		end
		return moves
	end
	add_piece(knight,r,c)
end

--creates a new bishop
function new_bishop(r,c,p)
	bishop = new_piece(r,c,p)
	bishop.sprnum = 4
	bishop.legmov = function(this)
	 local moves = {}
	 local direc = {{1, 1, true},{1, -1, true},{-1, -1, true},{-1, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  for d in all(direc) do
	   if d[3] then
	    s = get_pnum(r+i*d[1], c+i*d[2])
	    if s > 0 then
	     d[3] = false
	    end
	    if s != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	add_piece(bishop,r,c)
end

--creates a new rook
function new_rook(r,c,p)
	rook = new_piece(r,c,p)
	rook.sprnum = 6
	rook.legmov = function(this)
	 local moves = {}
	 local direc = {{1, 0, true},{0, -1, true},{-1, 0, true},{0, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  for d in all(direc) do
	   if d[3] then
	    s = get_pnum(r+i*d[1], c+i*d[2])
	    if s > 0 then
	     d[3] = false
	    end
	    if s != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	add_piece(rook,r,c)
end

--creates a new queen
function new_queen(r,c,p)
	queen = new_piece(r,c,p)
	queen.sprnum = 8
	queen.legmov = function(this)
	 local moves = {}
	 local direc = {{1, 1, true},{1, 0, true},{1, -1, true},{0, -1, true},{-1, -1, true},{-1, 0, true},{-1, 1, true},{0, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  for d in all(direc) do
	   if d[3] then
	    s = get_pnum(r+i*d[1], c+i*d[2])
	    if s > 0 then
	     d[3] = false
	    end
	    if s != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	add_piece(queen,r,c)
end

--creates a new king
function new_king(r,c,p)
	king = new_piece(r,c,p)
	king.sprnum = 10
	king.legmov = function(this)
	 local moves = {}
	 --calculate values one away
		oup = r-1
		odo = r+1
		ole = c-1
		ori = c+1
		local possi = {{oup, ole},{oup,ori},{r,ole},{r,ori},{odo,ole},{odo,ori},{odo,c},{oup,c}}
		for m in all(possi) do
		 if get_pnum(m[1], m[2]) != p then
		  add(moves, m)
		 end
		end
		return moves
	end
	add_piece(king,r,c)
end

function _update()
	--increment tick
	t = (t+1)%16
	--update hover
	update_hover()
end

--player button input
function update_hover()
	if(btnp(0) and hovc>1) then
		hovc = hovc-1
	end
	if(btnp(1) and hovc<8) then
		hovc = hovc+1
	end
	if(btnp(2) and hovr>1) then
		hovr = hovr-1
	end
	if(btnp(3) and hovr<8) then
		hovr = hovr+1
	end
	--update hover piece
	hovp = gb[hovr][hovc]
end

function _draw()
	draw_board()
	draw_every()
	draw_hover()
	--draw moves of piece hovered over
	if hovp > -1 then
	 draw_moves(pl[hovp])
	end
end

--draws the board
function draw_board()
	pal(1, 15)
	pal(2, 4)
	for r=1,8 do
		for c=1,8 do
			--draw background square
			rectfill(c*16-16, r*16-16, c*16-1, r*16-1, (r+c)%2+1)
		end
	end
	pal()
end

--draws every piece
function draw_every()
	foreach(pl, draw_piece)
end

--draws any given piece
function draw_piece(obj)
	palt(14)
	if(obj.pnum == 1) then
		pal(0, 7)
	end
	spr(obj.sprnum, obj.col*16-16, obj.row*16-16, 2, 2)
	pal()
end

--draws a piece's possible moves
function draw_moves(obj)
	moves = obj.legmov()
	foreach(moves, draw_amove)
end

--draws a single move
function draw_amove(move)
	r = move[1]
	c = move[2]
	rectfill(c*16-12, r*16-12, c*16-5, r*16-5, 11)
end

function draw_hover()
 if(t<8) then
		rect(hovc*16-16, hovr*16-16, hovc*16-1, hovr*16-1, 11)
	end
end
__gfx__
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0000000eeeeeeeee000eee00eeeeeeee0000000eeeeeeeee0000000eeeeeeeeeee0000eeeeeeeeee00eeee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00000000eeeeeeee0000ee00eeeeeeee00000000eeeeeeee00000000eeeeeeeee000000eeeeeeeee00eee000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00eeee00eeeeeeee0000ee00eeeeeeee00eeee00eeeeeeee00eeee00eeeeeeee000ee000eeeeeeee00ee000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00eeee00eeeeeeee0000ee00eeeeeeee00eeee00eeeeeeee00eeee00eeeeeeee00eeee00eeeeeeee00e000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00eeee00eeeeeeee00e00e00eeeeeeee00eeee00eeeeeeee00eeee00eeeeeeee00eeee00eeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00000000eeeeeeee00e00e00eeeeeeee0000000eeeeeeeee00000000eeeeeeee00eeee00eeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0000000eeeeeeeee00e00e00eeeeeeee0000000eeeeeeeee0000000eeeeeeeee00eeee00eeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00eeeeeeeeeeeeee00e00e00eeeeeeee00eeee00eeeeeeee00000eeeeeeeeeee00eeee00eeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00eeeeeeeeeeeeee00ee0000eeeeeeee00eeee00eeeeeeee00e000eeeeeeeeee00ee0e00eeeeeeee00e000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00eeeeeeeeeeeeee00ee0000eeeeeeee00eeee00eeeeeeee00ee000eeeeeeeee000ee000eeeeeeee00ee000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00eeeeeeeeeeeeee00ee0000eeeeeeee00000000eeeeeeee00eee000eeeeeeeee000000eeeeeeeee00eee000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee00eeeeeeeeeeeeee00eee000eeeeeeee0000000eeeeeeeee00eeee00eeeeeeeeee0000e0eeeeeeee00eeee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
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
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
