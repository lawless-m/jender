module Rays

using Vecs: Vec3

immutable Ray
	origin::Vec3
	direction::Vec3
	dot::Float64
	Ray(o, d) = new(o, d, dot(d, d))
end

function pointAt(r::Ray, t::Float64)
	r.origin + t * r.direction
end

end